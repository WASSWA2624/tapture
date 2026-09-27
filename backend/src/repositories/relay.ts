/// Columns a package row is allowed to carry. Nothing here is project content.
export const packageMetadataKeys = [
  'id',
  'projectId',
  'authorDeviceId',
  'byteSize',
  'createdAt',
  'expiresAt',
  'storageRef',
] as const;

export function assertAppendOnly(action: 'update' | 'delete'): never {
  throw new Error(`audit rows are append-only (${action})`);
}
