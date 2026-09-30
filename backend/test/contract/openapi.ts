import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { parse } from 'yaml';

export interface Schema {
  $ref?: string;
  type?: string;
  nullable?: boolean;
  required?: string[];
  properties?: Record<string, Schema>;
  items?: Schema;
  enum?: unknown[];
  oneOf?: Schema[];
  minLength?: number;
  minimum?: number;
  maximum?: number;
  additionalProperties?: boolean | Schema;
}

interface Response {
  $ref?: string;
  content?: Record<string, { schema: Schema }>;
}

export interface Operation {
  requestBody?: { content: Record<string, { schema: Schema }> };
  responses: Record<string, Response>;
}

export interface OpenApi {
  paths: Record<string, Record<string, Operation>>;
  components: {
    schemas: Record<string, Schema>;
    responses: Record<string, Response>;
  };
}

export async function readContract(): Promise<OpenApi> {
  const yaml = await readFile(
    fileURLToPath(new URL('../../openapi.yaml', import.meta.url)),
    'utf8',
  );
  const value: unknown = parse(yaml);
  if (
    typeof value !== 'object' ||
    value === null ||
    !('paths' in value) ||
    !('components' in value)
  ) {
    throw new Error('Invalid OpenAPI document.');
  }
  // The source document owns this supported OpenAPI subset; the comparisons
  // below verify every referenced schema against actual boundary values.
  return value as OpenApi;
}

export function schemaMismatches(
  doc: OpenApi,
  schema: Schema,
  value: unknown,
  field = 'body',
): string[] {
  if (schema.$ref !== undefined) {
    const target =
      doc.components.schemas[schema.$ref.replace('#/components/schemas/', '')];
    if (target === undefined) throw new Error(`Missing schema ${schema.$ref}`);
    return schemaMismatches(doc, target, value, field);
  }
  if (value === null && schema.nullable) return [];
  if (schema.oneOf !== undefined) {
    const matches = schema.oneOf.filter(
      (candidate) =>
        schemaMismatches(doc, candidate, value, field).length === 0,
    );
    return matches.length === 1 ? [] : [`${field}.oneOf`];
  }
  const errors: string[] = [];
  if (schema.enum !== undefined && !schema.enum.includes(value))
    errors.push(`${field}.enum`);
  if (schema.type === 'object') {
    if (typeof value !== 'object' || value === null || Array.isArray(value))
      return [...errors, field];
    const record = value as Record<string, unknown>;
    for (const name of schema.required ?? [])
      if (!(name in record)) errors.push(`${field}.${name}`);
    for (const [name, nested] of Object.entries(record)) {
      const property = schema.properties?.[name];
      if (property !== undefined)
        errors.push(
          ...schemaMismatches(doc, property, nested, `${field}.${name}`),
        );
      else if (schema.additionalProperties === false)
        errors.push(`${field}.${name}`);
      else if (typeof schema.additionalProperties === 'object')
        errors.push(
          ...schemaMismatches(
            doc,
            schema.additionalProperties,
            nested,
            `${field}.${name}`,
          ),
        );
    }
  } else if (schema.type === 'array') {
    if (!Array.isArray(value)) return [...errors, field];
    if (schema.items !== undefined)
      value.forEach((item: unknown, index) =>
        errors.push(
          ...schemaMismatches(
            doc,
            schema.items ?? {},
            item,
            `${field}[${index}]`,
          ),
        ),
      );
  } else if (schema.type === 'integer' || schema.type === 'number') {
    if (
      typeof value !== 'number' ||
      !Number.isFinite(value) ||
      (schema.type === 'integer' && !Number.isInteger(value))
    )
      return [...errors, field];
    if (schema.minimum !== undefined && value < schema.minimum)
      errors.push(field);
    if (schema.maximum !== undefined && value > schema.maximum)
      errors.push(field);
  } else if (schema.type !== undefined && typeof value !== schema.type)
    errors.push(field);
  if (
    typeof value === 'string' &&
    schema.minLength !== undefined &&
    value.length < schema.minLength
  )
    errors.push(field);
  return errors;
}

export function responseMismatches(
  doc: OpenApi,
  path: string,
  method: string,
  status: number,
  body: unknown,
): string[] {
  const operation = doc.paths[path]?.[method.toLowerCase()];
  if (operation === undefined) return [`${method} ${path}: operation`];
  let response =
    operation.responses[String(status)] ?? operation.responses['default'];
  if (response === undefined) return [`${method} ${path}: status ${status}`];
  if (response.$ref !== undefined)
    response =
      doc.components.responses[
        response.$ref.replace('#/components/responses/', '')
      ];
  if (response === undefined) throw new Error('Missing response reference.');
  const schema = response.content?.['application/json']?.schema;
  return schema === undefined
    ? []
    : schemaMismatches(doc, schema, body).map(
        (field) => `${method} ${path}: ${field}`,
      );
}
