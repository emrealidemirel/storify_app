import { spawnSync } from 'node:child_process';
// The standalone Firebase CLI may prepend its embedded Node to PATH.
// Keep the same modern Node runtime that started this test runner.
const quote = (value) => "'" + value.replaceAll("'", "'\\''") + "'";
const result = spawnSync('firebase', ['emulators:exec', '--only', 'storage',
  '--project', 'demo-storify', '--config', '../../firebase.json',
  `${quote(process.execPath)} storage_rules_test.mjs`], {stdio: 'inherit'});
if (result.error) console.error(result.error.message);
process.exit(result.status ?? 1);
