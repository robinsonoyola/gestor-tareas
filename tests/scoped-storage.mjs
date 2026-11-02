import assert from 'node:assert/strict'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { boardViewsStorageKey, legacyBoardViewsStorageKey } from '../src/lib/scopedStorage.js'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')

const first = boardViewsStorageKey('user-1', 'org-a')
assert.equal(first, 'ase-work-board-views-v2:user-1:org-a')
assert.notEqual(first, boardViewsStorageKey('user-2', 'org-a'))
assert.notEqual(first, boardViewsStorageKey('user-1', 'org-b'))
assert.equal(boardViewsStorageKey(null, 'org-a'), null)
assert.equal(boardViewsStorageKey('user-1', null), null)
assert.equal(legacyBoardViewsStorageKey, 'ase-work-board-views-v1')
const savedViews = fs.readFileSync(path.join(root, 'src/components/planning/BoardSavedViews.jsx'), 'utf8')
assert.ok(savedViews.includes('localStorage.removeItem(legacyBoardViewsStorageKey)'))

console.log(JSON.stringify({ passed: true, checks: 7 }))
