export const ACTION_REGISTRY = Object.freeze({
  'demo.echo': Object.freeze({
    type: 'demo.echo',
    riskLevel: 'low',
    permission: 'userApproval',
    approvalLevel: 1,
    requiresApproval: true,
    maxAmountMinor: null,
    allowedPayloadKeys: new Set(['text']),
  }),
  'demo.create_note': Object.freeze({
    type: 'demo.create_note',
    riskLevel: 'low',
    permission: 'userApproval',
    approvalLevel: 1,
    requiresApproval: true,
    maxAmountMinor: null,
    allowedPayloadKeys: new Set(['text']),
  }),
  'memory.save': Object.freeze({
    type: 'memory.save',
    riskLevel: 'low',
    permission: 'userApproval',
    approvalLevel: 1,
    requiresApproval: true,
    maxAmountMinor: null,
    allowedPayloadKeys: new Set(['key', 'value']),
  }),
});

export function getActionDefinition(type) {
  return ACTION_REGISTRY[type] ?? null;
}

export function validatePayload(definition, payload) {
  if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
    return false;
  }
  return Object.keys(payload).every((key) =>
    definition.allowedPayloadKeys.has(key)
  );
}
