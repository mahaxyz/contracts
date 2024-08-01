import assert from "assert";
import fs from "fs";
import path from "path";

export function get(name: string, network: string): string {
  const data = fs.readFileSync(
    path.resolve(__dirname, `../../deployments/${network}/${name}.json`)
  );

  const res = JSON.parse(data.toString()).address as any as string;
  assert(res.length == 42, `invalid address for ${network}/${name}.json`);
  return res;
}
