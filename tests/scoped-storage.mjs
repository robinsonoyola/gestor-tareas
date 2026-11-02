import assert from 'node:assert/strict'
import { boardViewsStorageKey } from '../src/lib/scopedStorage.js'

const first = boardViewsStorageKey('user-1', 'org-a')
assert.equal(first, 'ase-work-board-views-v2:user-1:org-a')
assert.notEqual(first, boardViewsStorageKey('user-2', 'org-a'))
assert.notEqual(first, boardViewsStorageKey('user-1', 'org-b'))
assert.equal(boardViewsStorageKey(null, 'org-a'), null)
assert.equal(boardViewsStorageKey('user-1', null), null)

console.log(JSON.stringify({ passed: true, checks: 5 }))
