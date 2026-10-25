import { readFile } from 'node:fs/promises';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getMetadata, deleteObject, listAll } from 'firebase/storage';

const env = await initializeTestEnvironment({
  projectId: 'demo-storify',
  storage: { rules: await readFile(new URL('../../storage.rules', import.meta.url), 'utf8') },
});
let passed = 0;
async function check(label, promise) { await promise; passed++; console.log(`PASS ${label}`); }
try {
  const owner = env.authenticatedContext('owner', {firebase: {sign_in_provider: 'password'}}).storage();
  const other = env.authenticatedContext('other', {firebase: {sign_in_provider: 'password'}}).storage();
  const guest = env.authenticatedContext('guest', {firebase: {sign_in_provider: 'anonymous'}}).storage();
  const nobody = env.unauthenticatedContext().storage();
  const image = new Uint8Array([255,216,255,0]);
  const metadata = {contentType: 'image/jpeg'};
  const path = 'users/owner/profile.jpg';
  await check('owner uploads profile', assertSucceeds(uploadBytes(ref(owner,path),image,metadata)));
  await check('owner reads own profile', assertSucceeds(getMetadata(ref(owner,path))));
  await check('other user cannot read profile', assertFails(getMetadata(ref(other,path))));
  await check('other user cannot overwrite profile', assertFails(uploadBytes(ref(other,path),image,metadata)));
  await check('signed-out read denied', assertFails(getMetadata(ref(nobody,path))));
  await check('guest profile upload denied', assertFails(uploadBytes(ref(guest,'users/guest/profile.jpg'),image,metadata)));
  await check('wrong MIME denied', assertFails(uploadBytes(ref(owner,path),image,{contentType:'text/html'})));
  await check('oversized photo denied', assertFails(uploadBytes(ref(owner,path),new Uint8Array(5*1024*1024+1),metadata)));
  const report = 'users/owner/reports/123.json';
  const data = new TextEncoder().encode('{"reason":"unsafe"}');
  const json = {contentType:'application/json'};
  await check('owner creates report', assertSucceeds(uploadBytes(ref(owner,report),data,json)));
  await check('reports cannot be overwritten', assertFails(uploadBytes(ref(owner,report),data,json)));
  await check('cross-account report denied', assertFails(uploadBytes(ref(other,'users/owner/reports/456.json'),data,json)));
  await check('other user cannot list reports', assertFails(listAll(ref(other,'users/owner/reports'))));
  await check('owner can list reports for deletion', assertSucceeds(listAll(ref(owner,'users/owner/reports'))));
  await check('oversized report denied', assertFails(uploadBytes(ref(owner,'users/owner/reports/789.json'),new Uint8Array(128*1024+1),json)));
  await check('unknown paths denied', assertFails(uploadBytes(ref(owner,'public/test.json'),data,json)));
  await check('other user cannot delete profile', assertFails(deleteObject(ref(other,path))));
  await check('owner can delete report', assertSucceeds(deleteObject(ref(owner,report))));
  await check('owner can delete profile', assertSucceeds(deleteObject(ref(owner,path))));
  console.log(`${passed} Storage rule checks passed.`);
} finally { await env.cleanup(); }
