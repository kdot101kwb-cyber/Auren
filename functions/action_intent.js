function normalizeAurenActionIntent(message) {
  const text = typeof message === 'string' ? message.trim().replace(/\s+/g, ' ') : '';
  if (!text) return null;

  const normalized = text.toLowerCase().replace(/[إأآ]/g, 'ا').replace(/ى/g, 'ي').replace(/ة/g, 'ه');
  const hasAny = (terms) => terms.some((term) => normalized.includes(term));

  if (hasAny(['احفظ في الذاكره', 'احفظ في الذاكرة', 'تذكر', 'افتكر', 'احفظ معلومة', 'remember', 'save to memory'])) {
    const patterns = [
      /(?:احفظ|تذكر|افتكر|خلي(?:ك)? تذكر|save|remember)[^:：-]{0,80}[:：-]\s*(.+?)\s*[=:：-]\s*(.+)$/i,
      /(?:مفتاح|key)\s*[:：=]\s*(.+?)\s+(?:قيمة|value)\s*[:：=]\s*(.+)$/i,
    ];
    for (const pattern of patterns) {
      const match = text.match(pattern);
      if (match) {
        const key = String(match[1]).trim();
        const value = String(match[2]).trim();
        if (key && value && key.length <= 120 && value.length <= 2000) {
          return {
            action: 'memory.save',
            payload: {key, value},
            text: 'سأحفظ هذه المعلومة في ذاكرة AUREN بعد موافقتك.',
          };
        }
      }
    }
  }

  if (hasAny(['انشئ ملاحظه', 'انشئ ملاحظة', 'اكتب ملاحظه', 'اكتب ملاحظة', 'سجل ملاحظه', 'سجل ملاحظة', 'اعمل ملاحظه', 'اعمل ملاحظة', 'create a note', 'make a note', 'write a note', 'add a note'])) {
    const match = text.match(/(?:انشئ|اكتب|سجل)\s+(?:لي\s+)?(?:ملاحظة|ملاحظه)\s*[:：-]?\s*(.+)$/i)
      || text.match(/(?:create|make|write)\s+(?:a\s+)?note\s*[:：-]?\s*(.+)$/i);
    if (match && match[1].trim().length <= 2000) {
      return {
        action: 'demo.create_note',
        payload: {text: match[1].trim()},
        text: 'سأنشئ الملاحظة بعد موافقتك.',
      };
    }
  }

  if (hasAny(['echo', 'ردد', 'كرر الكلام', 'قل لي نفس', 'repeat'])) {
    const match = text.match(/(?:echo|ردد|كرر الكلام|قل لي نفس|repeat)\s*[:：-]?\s*(.+)$/i);
    if (match && match[1].trim().length <= 2000) {
      return {
        action: 'demo.echo',
        payload: {text: match[1].trim()},
        text: 'سأكرر النص بعد موافقتك.',
      };
    }
  }

  return null;
}

function assertAurenActionPayload(action, payload) {
  if (!['demo.echo', 'demo.create_note', 'memory.save'].includes(action)) {
    throw new Error('Action is not allow-listed.');
  }
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    throw new Error('Invalid action payload.');
  }
  const keys = Object.keys(payload);
  if (action === 'memory.save') {
    if (keys.length !== 2 || !keys.includes('key') || !keys.includes('value') ||
        typeof payload.key !== 'string' || typeof payload.value !== 'string') {
      throw new Error('Invalid memory.save payload.');
    }
    if (!payload.key.trim() || !payload.value.trim() || payload.key.length > 120 || payload.value.length > 2000) {
      throw new Error('Invalid memory.save payload.');
    }
    return {key: payload.key.trim(), value: payload.value.trim()};
  }
  if (keys.length !== 1 || keys[0] !== 'text' || typeof payload.text !== 'string' ||
      !payload.text.trim() || payload.text.length > 2000) {
    throw new Error('Invalid text action payload.');
  }
  return {text: payload.text.trim()};
}

module.exports = { normalizeAurenActionIntent, assertAurenActionPayload };
