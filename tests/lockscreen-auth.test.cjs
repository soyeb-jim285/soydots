const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { test } = require('node:test');
const vm = require('node:vm');

const qml = readFileSync(`${__dirname}/../quickshell/LockScreen.qml`, 'utf8');

function body(marker) {
    const start = qml.indexOf(marker);
    assert.notEqual(start, -1, `Missing QML handler: ${marker}`);
    const opening = qml.indexOf('{', start);
    let depth = 1;
    let end = opening + 1;
    for (; depth > 0 && end < qml.length; end++) {
        if (qml[end] === '{') depth++;
        if (qml[end] === '}') depth--;
    }
    return qml.slice(opening + 1, end - 1);
}

function fixture() {
    const root = { locked: true, password: "test'\\password", status: 'idle', errorMsg: '' };
    const calls = [];
    const auth = {
        active: false,
        responseRequired: false,
        start() { calls.push('start'); return true; },
        respond(value) { calls.push(value); },
    };
    const context = vm.createContext({
        root, auth,
        PamResult: { Success: 0, Failed: 1, Error: 2, MaxTries: 3 },
        errorResetTimer: { restart() { calls.push('error reset'); } },
    });
    return { root, auth, calls, run: (marker, values = {}) => {
        Object.assign(context, values);
        vm.runInContext(`(() => {${body(marker)}})()`, context);
    } };
}

test('submission starts native authentication only when locked and idle', () => {
    const f = fixture();
    f.run('function tryUnlock()');
    assert.equal(f.root.status, 'verifying');
    assert.deepEqual(f.calls, ['start']);
    f.run('function tryUnlock()');
    assert.deepEqual(f.calls, ['start']);
    for (const change of [{ password: '' }, { locked: false }, { status: 'error' }]) {
        const blocked = fixture();
        Object.assign(blocked.root, change);
        blocked.run('function tryUnlock()');
        assert.deepEqual(blocked.calls, []);
    }
    const busy = fixture();
    busy.auth.active = true;
    busy.run('function tryUnlock()');
    assert.deepEqual(busy.calls, []);
});

test('PAM receives the exact password only when requesting a response', () => {
    const f = fixture();
    f.run('onPamMessage:');
    assert.deepEqual(f.calls, []);
    f.auth.responseRequired = true;
    f.run('onPamMessage:');
    assert.deepEqual(f.calls, ["test'\\password"]);
});

test('only successful authentication unlocks, without an extra timer', () => {
    const f = fixture();
    f.run('onCompleted: (result)', { result: 0 });
    assert.equal(f.root.locked, false);
    assert.equal(f.root.password, '');
    assert.deepEqual(f.calls, []);
    assert.doesNotMatch(qml, /id: unlockTimer|sudo -S|authProc/);
});

test('failed authentication and PAM errors keep the session locked', () => {
    for (const result of [1, 2, 3]) {
        const f = fixture();
        f.run('onCompleted: (result)', { result });
        assert.equal(f.root.locked, true);
        assert.equal(f.root.password, '');
        assert.equal(f.root.status, 'error');
        assert.ok(f.root.errorMsg.length > 0);
        assert.deepEqual(f.calls, ['error reset']);
    }
});

test('failure to start authentication fails closed', () => {
    const f = fixture();
    f.auth.start = () => false;
    f.run('function tryUnlock()');
    assert.equal(f.root.locked, true);
    assert.equal(f.root.password, '');
    assert.equal(f.root.status, 'error');
    assert.deepEqual(f.calls, ['error reset']);
});
