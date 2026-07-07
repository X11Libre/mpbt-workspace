import type { Plugin } from "@opencode-ai/plugin";

export default (async ({ client }) => {
  const shipName = process.env.AGENT_ID;
  if (!shipName) return {};

  return {
    event: async ({ event }) => {
      if (event.type === "session.created") {
        const sessionId = event.properties.info.id;
        await client.session.update({
          path: { id: sessionId },
          body: { title: shipName },
        });
      }
    },
  };
}) satisfies Plugin;
