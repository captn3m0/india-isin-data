import { DB } from "https://deno.land/x/sqlite/mod.ts";
import {
  app,
  get,
  post,
  redirect,
  contentType,
} from "https://denopkg.com/syumai/dinatra@0.15.0/mod.ts";

const db = new DB("ISIN.db", { mode: "read" });

app(
  get("/api/:isin", ({ params }) => {
    let query = `SELECT * from ISIN WHERE ISIN='${params.isin}'`
    let res = db.query(query);

    if (res.length == 1) {
      let [isin,description,issuer,type,status] = res[0]
      if (issuer == "null") {
        issuer = null
      }
      return [200, contentType("json"), JSON.stringify({ isin,description,issuer,type,status })]
    } else {
      return[404, contentType("json"), "Invalid ISIN"]
    }
  })
);