import { randomUUID } from 'node:crypto';
import type { AppConfig } from '../../config/schema.js';
import { normaliseEmail } from '../../domain/email.js';
import { conflict, invalidRequest } from '../../domain/errors.js';
import type { Repository } from '../../repositories/repository.js';
import { hashPassword } from './password.js';

/// Local operator command only. Refuses to replace an existing organisation.
export async function bootstrapOrganisation(
  store: Repository,
  config: AppConfig,
  input: { name: string; email: string; password: string },
): Promise<{ organisationId: string; userId: string }> {
  const email = normaliseEmail(input.email);
  if (
    input.password.length < 12 ||
    !email.includes('@') ||
    !input.name.trim()
  ) {
    throw invalidRequest(
      'Provide an organisation, email and password of at least 12 characters.',
    );
  }
  const passwordHash = await hashPassword(input.password, config);
  return store.withTransaction(async (tx) => {
    if ((await tx.orgs()).length > 0)
      throw conflict('This deployment already has an organisation.');
    const organisationId = randomUUID();
    const userId = randomUUID();
    await tx.addOrg({
      id: organisationId,
      name: input.name.trim(),
      selfRegister: false,
      retentionDays: config.retentionDays,
    });
    await tx.addUser({
      id: userId,
      organisationId,
      email,
      passwordHash,
      role: 'administrator',
      status: 'active',
    });
    await tx.recordAudit({
      actorId: userId,
      action: 'bootstrap_organisation',
      target: organisationId,
      before: null,
      after: { role: 'administrator' },
    });
    return { organisationId, userId };
  });
}
