/// Holds a provider key. Callers receive a client, never the key.
export class KeyCustody {
  readonly #key: string;

  constructor(key: string) {
    this.#key = key;
  }

  client(): { configured: boolean } {
    return { configured: this.#key.length > 0 };
  }
}
