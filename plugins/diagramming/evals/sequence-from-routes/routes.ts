// Eval fixture: Elysia-style auth routes used to derive a sequence diagram.
// The skill should walk this file to extract endpoints, methods, and downstream calls.

import { Elysia } from "elysia";

export const authRoutes = new Elysia({ prefix: "/auth" })
  .post("/login", async ({ body, set }) => {
    const user = await db.user.findByEmail(body.email);
    if (!user) {
      set.status = 401;
      return { error: "invalid_credentials" };
    }

    const ok = await passwords.verify(body.password, user.passwordHash);
    if (!ok) {
      set.status = 401;
      return { error: "invalid_credentials" };
    }

    const token = await jwt.sign({ sub: user.id });
    return { token };
  })
  .post("/logout", async ({ headers, set }) => {
    const token = headers.authorization?.split(" ")[1];
    if (!token) {
      set.status = 400;
      return { error: "missing_token" };
    }
    await jwt.revoke(token);
    return { ok: true };
  });
