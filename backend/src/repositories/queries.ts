export interface PageQuery {
  readonly cursor?: string;
  readonly limit?: number;
}

export interface UserQuery extends PageQuery {
  readonly organisationId?: string;
}

export interface DeviceQuery extends PageQuery {
  readonly userId?: string;
  readonly projectId?: string;
  readonly activeOnly?: boolean;
}

export interface ProjectQuery extends PageQuery {
  readonly id?: string;
  readonly organisationId?: string;
  readonly memberUserId?: string;
}

export interface MembershipQuery extends PageQuery {
  readonly projectId?: string;
  readonly userId?: string;
}

export interface PackagePosition {
  readonly createdAt: string;
  readonly id: string;
}

export interface PackageQuery {
  readonly id?: string;
  readonly projectId?: string;
  readonly unacknowledgedDeviceId?: string;
  readonly activeAfter?: string;
  readonly after?: PackagePosition;
  readonly limit?: number;
}

export interface AckQuery {
  readonly packageId?: string;
  readonly deviceId?: string;
}

export interface UsageQuery extends PageQuery {
  readonly projectId: string;
  readonly userId: string;
  readonly from: string;
  readonly to: string;
}

/// The fake and production repository use the same identifier keyset order.
export function identifierPage<T>(
  rows: readonly T[],
  query: PageQuery,
  identifier: (row: T) => string,
): T[] {
  return rows
    .filter(
      (row) => query.cursor === undefined || identifier(row) > query.cursor,
    )
    .sort((left, right) => compareText(identifier(left), identifier(right)))
    .slice(0, query.limit);
}

export function compareText(left: string, right: string): number {
  return left < right ? -1 : left > right ? 1 : 0;
}
