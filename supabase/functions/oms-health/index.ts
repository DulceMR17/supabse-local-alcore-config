const headers = {
  "content-type": "application/json; charset=utf-8",
  "cache-control": "no-store",
};

Deno.serve(() => {
  return new Response(
    JSON.stringify({
      service: "oms-supabase",
      status: "ok",
      schemas: ["oms", "ref", "legacy", "staging"],
      legacyTablesMapped: 1180,
      legacyFieldsMapped: 41460,
      normalizedTables: 26,
    }),
    { headers },
  );
});
