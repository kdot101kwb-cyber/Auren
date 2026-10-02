
  Widget _buildContinueListening() {
    final item = _player.item;
    final duration = _player.duration;
    final position = _player.position;
    if (item == null || item.mediaUrl.isEmpty ||
        position <= const Duration(seconds: 10) ||
        (duration > Duration.zero && position >= duration * 0.95)) {
      return const SizedBox.shrink();
    }
    final total = duration.inMilliseconds;
    final progress = total <= 0
        ? 0.0
        : position.inMilliseconds.clamp(0, total).toDouble() / total;
    return AnimatedBuilder(
      animation: _player,
      builder: (context, _) => Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                item.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(item.imageUrl, width: 64, height: 64, fit: BoxFit.cover),
                      )
                    : const SizedBox(width: 64, height: 64, child: Icon(Icons.podcasts, size: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('تابع الاستماع', style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      if (duration > Duration.zero) LinearProgressIndicator(value: progress),
                      if (duration > Duration.zero) const SizedBox(height: 4),
                      Text(
                        '${_formatDuration(_player.position)} / ${_formatDuration(_player.duration)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'استمرار',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AurenAudioPlayerScreen(item: item)),
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 36),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;