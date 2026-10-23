import fs from 'node:fs';import assert from 'node:assert/strict';
const source=fs.readFileSync(new URL('../../src/lib/taskCardNfc.js',import.meta.url),'utf8');
const {normalizeTaskCardUid,readTaskCardUid}=await import('data:text/javascript;base64,'+Buffer.from(source).toString('base64'));
assert.equal(normalizeTaskCardUid('04:A1:B2:C3:D4:E5:F6'),'04a1b2c3d4e5f6');assert.equal(normalizeTaskCardUid('04-a1-b2-c3-d4-e5-f6'),'04a1b2c3d4e5f6');
for(const value of ['', 'ASE-personal-credential','04:GG:00:11','123'])assert.throws(()=>normalizeTaskCardUid(value));
let reader;class FakeReader{constructor(){reader=this}async scan({signal}){this.signal=signal}}
const controller=new AbortController();let received=[],errors=[];
await readTaskCardUid({Reader:FakeReader,secure:true,signal:controller.signal,onRead:v=>received.push(v),onError:e=>errors.push(e)});
const handler=reader.onreading;handler({serialNumber:'04:A1:B2:C3:D4:E5:F6'});handler({serialNumber:'04:A1:B2:C3:D4:E5:F6'});assert.deepEqual(received,['04a1b2c3d4e5f6']);assert.equal(reader.onreading,null);
const canceled=new AbortController();await readTaskCardUid({Reader:FakeReader,secure:true,signal:canceled.signal,onRead:v=>received.push(v),onError:e=>errors.push(e)});const queued=reader.onreading;canceled.abort();queued({serialNumber:'04:A1:B2:C3:D4:E5:F6'});assert.equal(received.length,1);assert.equal(reader.onreading,null);
await assert.rejects(readTaskCardUid({secure:false,Reader:FakeReader}),/HTTPS/);await assert.rejects(readTaskCardUid({secure:true,Reader:null}),/navegador/);
console.log('PASS: UID normalization, invalid formats, one callback per read, cancellation, HTTPS and reader availability');
