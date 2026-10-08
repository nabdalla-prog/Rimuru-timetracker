// Run with: node --test tests/
// Model.js is a QML `.pragma library` file, so it is evaluated in a sandbox.
const test = require("node:test")
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs
  .readFileSync(path.join(__dirname, "..", "js", "Model.js"), "utf8")
  .replace(/^\.pragma library$/m, "")
const M = vm.createContext({})
vm.runInContext(source, M)

const plain = (x) => JSON.parse(JSON.stringify(x))
const T = (y, mo, d, h = 0, mi = 0) => new Date(y, mo - 1, d, h, mi).getTime()
const now = T(2026, 10, 7, 12)

test("default data has the reference activities", () => {
  const d = M.defaultData(now)
  assert.equal(d.activities.length, 12)
  assert.equal(d.activities[0].name, "School")
  assert.equal(d.settings.displayStyle, "grid")
})

test("parseData: empty text gives defaults, junk is reported", () => {
  assert.equal(M.parseData("", now).ok, true)
  assert.equal(M.parseData("{nope", now).ok, false)
  assert.equal(M.parseData("[]", now).ok, false)
})

test("parseData drops bad rows and keeps good ones", () => {
  const text = JSON.stringify({
    activities: [{ id: "a", name: "Work", color: "#123456" }, { id: "a", name: "dup" }, { id: "b", name: "X", color: "red" }],
    events: [{ id: "e1", activity: "a", start: 10, end: 20 }, { activity: "zz", start: 1, end: 2 }, { activity: "a", start: 5, end: 1 }],
    running: [{ activity: "b", start: 3 }, { activity: "q", start: 3 }],
    goals: [{ activity: "a", minutes: 30, period: "week" }, { activity: "a", minutes: -1 }],
    settings: { simultaneous: true, timeFormat: 5, hidden: ["b"] }
  })
  const r = M.parseData(text, now)
  assert.equal(r.ok, true)
  assert.equal(r.data.activities.length, 2)
  assert.match(r.data.activities[1].color, /^#[0-9a-f]{6}$/i)
  assert.equal(r.data.events.length, 1)
  assert.equal(r.data.running.length, 1)
  assert.equal(r.data.goals.length, 1)
  assert.equal(r.data.goals[0].period, "week")
  assert.equal(r.data.settings.simultaneous, true)
  assert.equal(r.data.settings.timeFormat, "hm")
  assert.deepEqual(plain(r.data.settings.hidden), ["b"])
})

test("starting a timer stops the other one unless simultaneous", () => {
  let d = M.defaultData(now)
  d = M.startTimer(d, "a1", now)
  d = M.startTimer(d, "a2", now + 60000)
  assert.equal(d.running.length, 1)
  assert.equal(d.running[0].activity, "a2")
  assert.equal(d.events.length, 1)
  assert.equal(d.events[0].end - d.events[0].start, 60000)

  d = M.setSetting(d, "simultaneous", true)
  d = M.startTimer(d, "a3", now + 120000)
  assert.equal(d.running.length, 2)
})

test("toggle stops a running timer and records the event", () => {
  let d = M.defaultData(now)
  d = M.toggleTimer(d, "a1", now)
  d = M.toggleTimer(d, "a1", now + 90 * 60000)
  assert.equal(d.running.length, 0)
  assert.equal(d.events.length, 1)
})

test("rounding rounds the stopped event, and drops rounded-away ones", () => {
  let d = M.setSetting(M.defaultData(now), "rounding", 15)
  d = M.toggleTimer(d, "a1", now)
  d = M.toggleTimer(d, "a1", now + 22 * 60000)
  assert.equal(d.events[0].end - d.events[0].start, 15 * 60000)
  d = M.toggleTimer(d, "a1", now)
  d = M.toggleTimer(d, "a1", now + 5 * 60000)
  assert.equal(d.events.length, 1)
})

test("a timer stopped within a second leaves no event", () => {
  let d = M.defaultData(now)
  d = M.toggleTimer(d, "a1", now)
  d = M.toggleTimer(d, "a1", now + 400)
  assert.equal(d.events.length, 0)
  assert.equal(d.running.length, 0)
})

test("fmt", () => {
  assert.equal(M.fmt(0), "0s")
  assert.equal(M.fmt(30000), "30s")
  assert.equal(M.fmt(5 * 60000), "5m")
  assert.equal(M.fmt(252 * 60000), "4h 12m")
  assert.equal(M.fmt(252 * 60000, "clock"), "4:12")
  assert.equal(M.fmt(252 * 60000, "decimal"), "4.2h")
  assert.equal(M.fmtElapsed(3723000), "1:02:03")
  assert.equal(M.fmtElapsed(65000), "1:05")
  assert.equal(M.fmtEvent(30000, "hm"), "30 sec")
  assert.equal(M.fmtEvent(86 * 60000, "hm"), "1h 26m")
})

test("clock and dayTitle", () => {
  assert.equal(M.clock(T(2026, 9, 19, 6, 18)), "6:18 AM")
  assert.equal(M.clock(T(2026, 9, 19, 0, 5)), "12:05 AM")
  assert.equal(M.clock(T(2026, 9, 19, 22, 44)), "10:44 PM")
  assert.equal(M.dayTitle(T(2026, 9, 19)), "Saturday, Sep 19")
})

test("totals clip events to the range and include running timers", () => {
  let d = M.defaultData(now)
  d = M.saveEvent(d, { activity: "a1", start: T(2026, 10, 6, 23), end: T(2026, 10, 7, 1) })
  d = M.saveEvent(d, { activity: "a3", start: T(2026, 10, 7, 9), end: T(2026, 10, 7, 10) })
  d = M.startTimer(d, "a1", T(2026, 10, 7, 11))
  const r = M.periodRange("day", 0, now, 1)
  const rows = M.totals(d, now, r.from, r.to, [])
  assert.equal(rows[0].id, "a1")
  assert.equal(rows[0].ms, 2 * 3600000)
  assert.equal(rows[0].count, 2)
  assert.equal(rows[1].ms, 3600000)
  assert.equal(M.totals(d, now, r.from, r.to, ["a1"]).length, 1)
})

test("periodRange", () => {
  const w = M.periodRange("week", 0, now, 1)
  assert.equal(new Date(w.from).getDay(), 1)
  assert.equal(w.label, "Oct 5 – 11")
  assert.equal(new Date(M.periodRange("week", 0, now, 0).from).getDay(), 0)
  assert.equal(M.periodRange("month", 1, now, 1).label, "September 2026")
  assert.equal(M.periodRange("month", 10, now, 1).label, "December 2025")
  assert.equal(M.periodRange("year", 0, now, 1).label, "2026")
  assert.equal(M.periodRange("day", 1, now, 1).label, "Yesterday")
})

test("eventLog groups newest first", () => {
  let d = M.defaultData(now)
  d = M.saveEvent(d, { activity: "a1", start: T(2026, 9, 17, 21, 17), end: T(2026, 9, 17, 22, 44) })
  d = M.saveEvent(d, { activity: "a1", start: T(2026, 9, 19, 6, 18), end: T(2026, 9, 19, 6, 19) })
  d = M.saveEvent(d, { activity: "a2", start: T(2026, 9, 19, 8), end: T(2026, 9, 19, 9) })
  const log = M.eventLog(d, now)
  assert.equal(log.length, 2)
  assert.equal(log[0].title, "Saturday, Sep 19")
  assert.equal(log[0].count, 2)
  assert.equal(log[0].events[0].activity, "a2")
})

test("goals for the day and week", () => {
  let d = M.defaultData(now)
  d = M.saveGoal(d, { activity: "a1", period: "day", minutes: 60 }, now)
  d = M.saveGoal(d, { activity: "a11", period: "week", minutes: 30, kind: "atMost" }, now)
  d = M.saveEvent(d, { activity: "a1", start: T(2026, 10, 7, 8), end: T(2026, 10, 7, 8, 30) })
  d = M.saveEvent(d, { activity: "a11", start: T(2026, 10, 5, 8), end: T(2026, 10, 5, 9) })
  const g = M.goalStatus(d, now)
  assert.equal(g[0].ratio, 0.5)
  assert.equal(g[0].reached, false)
  assert.equal(g[1].over, true)
})

test("deleteActivity removes its events, goals and timer", () => {
  let d = M.defaultData(now)
  d = M.saveEvent(d, { activity: "a1", start: 1, end: 2 })
  d = M.saveGoal(d, { activity: "a1", minutes: 5 }, now)
  d = M.startTimer(d, "a1", now)
  d = M.deleteActivity(d, "a1")
  assert.equal(d.events.length + d.goals.length + d.running.length, 0)
  assert.equal(d.activities.length, 11)
})

test("toCsv escapes names", () => {
  let d = M.addActivity(M.defaultData(now), 'Say "hi", ok', "#123456", now)
  const id = d.activities[d.activities.length - 1].id
  d = M.saveEvent(d, { activity: id, start: T(2026, 10, 7, 8), end: T(2026, 10, 7, 8, 30) })
  const csv = M.toCsv(d, now)
  assert.match(csv, /^activity,start,end,duration_minutes\n"Say ""hi"", ok",2026-10-07 08:00:00,2026-10-07 08:30:00,30.0\n$/)
})

test("Model.VERSION matches manifest.json and the changelog", () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(__dirname, "..", "manifest.json"), "utf8"))
  assert.equal(M.VERSION, manifest.version)
  const changelog = fs.readFileSync(path.join(__dirname, "..", "CHANGELOG.md"), "utf8")
  assert.match(changelog, new RegExp("## " + M.VERSION.replace(/\./g, "\\.") + "\\b"))
})
