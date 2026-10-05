                },
              ),
            ),
          if (!_isAi && _otherUid != null)
            StreamBuilder<bool>(
              stream: _typing.watchTyping(_conversationId!, _otherUid!),
              builder: (_, snapshot) => snapshot.data == true
                  ? const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('يكتب الآن…'),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          if (_showDetails)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Text(
                'Conversation: ' + _conversationId! +
                    '\nAI actions require your approval before execution.',
              ),
            ),
          Expanded(
            child: StreamBuilder<DateTime?>(
              stream: _isAi || _otherUid == null
                  ? null
                  : _conversationRepository.watchReadAt(_conversationId!, _otherUid!),
              builder: (context, readSnapshot) {
                final readAt = readSnapshot.data;
                return StreamBuilder<List<AurenMessage>>(
                  stream: _messagesRepository.watchConversation(_conversationId!),
                  builder: (context, snapshot) {
                    if (readSnapshot.hasError) {
                      return Center(child: Text('Could not load read status: ${readSnapshot.error}'));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Could not load messages: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data!;
                    if (!_isAi && _uid != null) {
                      final now = DateTime.now();
                      final last = _lastReadMarkAt;
                      if (last == null || now.difference(last) >= const Duration(seconds: 5)) {
                        _lastReadMarkAt = now;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _conversationRepository.markRead(_conversationId!, _uid!);
                          }
                        });
                      }
                    }
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(_isAi ? 'ابدأ محادثتك مع AUREN AI' : 'ابدأ المحادثة'),
                      );
                    }
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = !message.isAi && message.senderId == _uid;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: mine
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: GestureDetector(
                              onLongPress: () => _messageMenu(message),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(child: Text(message.text)),
                                  _messageStatus(message, readAt),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onChanged: (value) {
                        setState(() {});
                        if (!_isAi && _uid != null && _conversationId != null) {
                          _typing.setTyping(_conversationId!, _uid!, value.trim().isNotEmpty);
                          if (value.trim().isNotEmpty) _typing.scheduleStop(_conversationId!, _uid!);
                        }
                      },