.pragma library

// Pure logic for Time Tracker: no QML, no I/O, so it can be unit tested with
// plain Node (see tests/model.test.js).
//
// Data shape (saved as JSON):
//   activities: [{ id, name, color, archived }]
//   events:     [{ id, activity, start, end }]   finished stretches, ms epoch
//   running:    [{ activity, start }]             timers still going
//   goals:      [{ id, activity, period: "day"|"week", minutes, kind: "atLeast"|"atMost" }]
//   settings:   see DEFAULT_SETTINGS
//
// Every function returns new objects instead of changing its input, so QML
// bindings that read the result re-evaluate.

var VERSION = "0.1.0"
var DATA_VERSION = 1

var MINUTE = 60000
var HOUR = 3600000
var DAY = 86400000

// The colours from the reference, plus a few extra for new activities.
var PALETTE = [
  "#0a9fd8", "#22c32e", "#ff2d2d", "#1f5fae", "#7a9a1e", "#e8822a",
  "#d9572a", "#cdaa2b", "#6c2bb0", "#c81e64", "#2b3aa0", "#b9ad44",
  "#18b5a5", "#8e8e93", "#ff6fb5", "#a0522d"
]

var DEFAULT_ACTIVITIES = [
  ["School", "#0a9fd8"], ["Sleep", "#22c32e"],
  ["Productive", "#ff2d2d"], ["Reading", "#1f5fae"],
  ["Work", "#7a9a1e"], ["Socializing", "#e8822a"],
  ["Running", "#d9572a"], ["Driving", "#cdaa2b"],
  ["Personal Development", "#6c2bb0"], ["Meditating", "#c81e64"],
  ["Movies", "#2b3aa0"], ["Social media", "#b9ad44"]
]

var DEFAULT_SETTINGS = {
  displayStyle: "grid",      // "grid" | "list"
  simultaneous: false,       // several timers at once
  timeFormat: "hm",          // "hm" 4h 12m | "clock" 4:12 | "decimal" 4.2h
  rounding: 0,               // minutes events are rounded to when stopped
  weekStart: 1,              // 1 Monday, 0 Sunday
  reminderHours: 0,          // notify when a timer has run this long, 0 = off
  goalNotifications: true,
  pieLabels: "percent",      // "percent" | "time"
  hidden: []                 // activity ids hidden from the timeline
}

function pad(n) {
  return n < 10 ? "0" + n : "" + n
}

function newId(prefix, now) {
  return prefix + now.toString(36) + Math.floor(Math.random() * 1e6).toString(36)
}

function dayKey(date) {
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate())
}

function startOfDay(ms) {
  var d = new Date(ms)
  return new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
}

function addDays(ms, n) {
  var d = new Date(ms)
  return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n, d.getHours(), d.getMinutes(), d.getSeconds(), d.getMilliseconds()).getTime()
}

function startOfWeek(ms, weekStart) {
  var day0 = startOfDay(ms)
  var dow = new Date(day0).getDay()
  var back = (dow - weekStart + 7) % 7
  return addDays(day0, -back)
}

// ---- Data ------------------------------------------------------------------

function defaultData(now) {
  var acts = []
  for (var i = 0; i < DEFAULT_ACTIVITIES.length; i++)
    acts.push({ id: "a" + (i + 1), name: DEFAULT_ACTIVITIES[i][0], color: DEFAULT_ACTIVITIES[i][1], archived: false })
  return { version: DATA_VERSION, activities: acts, events: [], running: [], goals: [], settings: Object.assign({}, DEFAULT_SETTINGS) }
}

function isNum(v) {
  return typeof v === "number" && isFinite(v)
}

function validColor(c) {
  return typeof c === "string" && /^#[0-9a-fA-F]{6}$/.test(c)
}

// Parses saved text. Returns { ok, data }; ok is false for unreadable text,
// in which case the caller keeps a copy instead of overwriting it.
function parseData(text, now) {
  if (!text || !String(text).trim())
    return { ok: true, data: defaultData(now) }
  var raw
  try {
    raw = JSON.parse(text)
  } catch (e) {
    return { ok: false, data: defaultData(now) }
  }
  if (!raw || typeof raw !== "object" || Array.isArray(raw))
    return { ok: false, data: defaultData(now) }
  var out = { version: DATA_VERSION, activities: [], events: [], running: [], goals: [], settings: Object.assign({}, DEFAULT_SETTINGS) }
  var ids = {}
  ;(Array.isArray(raw.activities) ? raw.activities : []).forEach(function (a) {
    if (!a || typeof a.id !== "string" || ids[a.id] || typeof a.name !== "string")
      return
    ids[a.id] = true
    out.activities.push({ id: a.id, name: a.name.slice(0, 40), color: validColor(a.color) ? a.color : PALETTE[out.activities.length % PALETTE.length], archived: a.archived === true })
  })
  ;(Array.isArray(raw.events) ? raw.events : []).forEach(function (e) {
    if (!e || !ids[e.activity] || !isNum(e.start) || !isNum(e.end) || e.end < e.start)
      return
    out.events.push({ id: typeof e.id === "string" ? e.id : newId("e", e.start), activity: e.activity, start: e.start, end: e.end })
  })
  ;(Array.isArray(raw.running) ? raw.running : []).forEach(function (r) {
    if (r && ids[r.activity] && isNum(r.start))
      out.running.push({ activity: r.activity, start: r.start })
  })
  ;(Array.isArray(raw.goals) ? raw.goals : []).forEach(function (g) {
    if (!g || !ids[g.activity] || !isNum(g.minutes) || g.minutes <= 0)
      return
    out.goals.push({ id: typeof g.id === "string" ? g.id : newId("g", now), activity: g.activity, period: g.period === "week" ? "week" : "day", minutes: Math.round(g.minutes), kind: g.kind === "atMost" ? "atMost" : "atLeast" })
  })
  var s = raw.settings && typeof raw.settings === "object" ? raw.settings : {}
  for (var k in DEFAULT_SETTINGS)
    if (s[k] !== undefined && typeof s[k] === typeof DEFAULT_SETTINGS[k] && Array.isArray(s[k]) === Array.isArray(DEFAULT_SETTINGS[k]))
      out.settings[k] = s[k]
  out.events.sort(function (a, b) { return a.start - b.start })
  return { ok: true, data: out }
}

function serialize(data) {
  return JSON.stringify(data, null, 1)
}

function activityById(data, id) {
  for (var i = 0; i < data.activities.length; i++)
    if (data.activities[i].id === id)
      return data.activities[i]
  return null
}

function visibleActivities(data) {
  return data.activities.filter(function (a) { return !a.archived })
}

function isRunning(data, id) {
  for (var i = 0; i < data.running.length; i++)
    if (data.running[i].activity === id)
      return data.running[i]
  return null
}

// ---- Timers ------------------------------------------------------------------

function roundEnd(start, end, minutes) {
  if (!minutes || minutes <= 0)
    return end
  var step = minutes * MINUTE
  var len = Math.round((end - start) / step) * step
  return start + Math.max(0, len)
}

function stopTimer(data, id, now) {
  var r = isRunning(data, id)
  if (!r)
    return data
  var next = Object.assign({}, data)
  next.running = data.running.filter(function (x) { return x.activity !== id })
  var end = roundEnd(r.start, Math.max(r.start, now), data.settings.rounding)
  // A stretch rounded down to nothing (or a mis-click under a second) isn't
  // worth an event.
  if (end - r.start >= 1000)
    next.events = data.events.concat([{ id: newId("e", now), activity: id, start: r.start, end: end }])
  return next
}

function stopAll(data, now) {
  var next = data
  data.running.forEach(function (r) { next = stopTimer(next, r.activity, now) })
  return next
}

function startTimer(data, id, now) {
  if (isRunning(data, id) || !activityById(data, id))
    return data
  var next = data.settings.simultaneous ? data : stopAll(data, now)
  next = Object.assign({}, next)
  next.running = next.running.concat([{ activity: id, start: now }])
  return next
}

function toggleTimer(data, id, now) {
  return isRunning(data, id) ? stopTimer(data, id, now) : startTimer(data, id, now)
}

// ---- Editing -------------------------------------------------------------------

function addActivity(data, name, color, now) {
  var clean = String(name || "").trim().slice(0, 40)
  if (!clean)
    return data
  var next = Object.assign({}, data)
  next.activities = data.activities.concat([{ id: newId("a", now), name: clean, color: validColor(color) ? color : PALETTE[data.activities.length % PALETTE.length], archived: false }])
  return next
}

function updateActivity(data, id, changes) {
  var next = Object.assign({}, data)
  next.activities = data.activities.map(function (a) {
    if (a.id !== id)
      return a
    var b = Object.assign({}, a)
    if (changes.name !== undefined && String(changes.name).trim())
      b.name = String(changes.name).trim().slice(0, 40)
    if (changes.color !== undefined && validColor(changes.color))
      b.color = changes.color
    if (changes.archived !== undefined)
      b.archived = changes.archived === true
    return b
  })
  // An archived activity stops its timer.
  if (changes.archived === true)
    return stopTimer(next, id, Date.now())
  return next
}

// Removes an activity with all its events, goals and its timer.
function deleteActivity(data, id) {
  var next = Object.assign({}, data)
  next.activities = data.activities.filter(function (a) { return a.id !== id })
  next.events = data.events.filter(function (e) { return e.activity !== id })
  next.running = data.running.filter(function (r) { return r.activity !== id })
  next.goals = data.goals.filter(function (g) { return g.activity !== id })
  next.settings = Object.assign({}, data.settings, { hidden: data.settings.hidden.filter(function (h) { return h !== id }) })
  return next
}

function moveActivity(data, id, delta) {
  var list = data.activities.slice()
  var i = -1
  for (var k = 0; k < list.length; k++)
    if (list[k].id === id)
      i = k
  var j = i + delta
  if (i < 0 || j < 0 || j >= list.length)
    return data
  var t = list[i]
  list[i] = list[j]
  list[j] = t
  return Object.assign({}, data, { activities: list })
}

function saveEvent(data, ev) {
  if (!activityById(data, ev.activity) || !isNum(ev.start) || !isNum(ev.end) || ev.end <= ev.start)
    return data
  var next = Object.assign({}, data)
  var found = false
  next.events = data.events.map(function (e) {
    if (e.id !== ev.id)
      return e
    found = true
    return { id: e.id, activity: ev.activity, start: ev.start, end: ev.end }
  })
  if (!found)
    next.events.push({ id: ev.id || newId("e", ev.start), activity: ev.activity, start: ev.start, end: ev.end })
  next.events.sort(function (a, b) { return a.start - b.start })
  return next
}

function deleteEvent(data, id) {
  return Object.assign({}, data, { events: data.events.filter(function (e) { return e.id !== id }) })
}

function saveGoal(data, goal, now) {
  if (!activityById(data, goal.activity) || !(goal.minutes > 0))
    return data
  var g = { id: goal.id || newId("g", now), activity: goal.activity, period: goal.period === "week" ? "week" : "day", minutes: Math.round(goal.minutes), kind: goal.kind === "atMost" ? "atMost" : "atLeast" }
  var next = Object.assign({}, data)
  var found = false
  next.goals = data.goals.map(function (x) {
    if (x.id !== g.id)
      return x
    found = true
    return g
  })
  if (!found)
    next.goals.push(g)
  return next
}

function deleteGoal(data, id) {
  return Object.assign({}, data, { goals: data.goals.filter(function (g) { return g.id !== id }) })
}

function setSetting(data, key, value) {
  var s = Object.assign({}, data.settings)
  s[key] = value
  return Object.assign({}, data, { settings: s })
}

function toggleHidden(data, id) {
  var hidden = data.settings.hidden
  var next = hidden.indexOf(id) >= 0 ? hidden.filter(function (h) { return h !== id }) : hidden.concat([id])
  return setSetting(data, "hidden", next)
}

// ---- Formatting -------------------------------------------------------------------

function fmt(ms, format) {
  if (!isNum(ms) || ms < 0)
    ms = 0
  if (format === "clock") {
    var tm = Math.floor(ms / MINUTE)
    return Math.floor(tm / 60) + ":" + pad(tm % 60)
  }
  if (format === "decimal") {
    var h = ms / HOUR
    return (h < 10 ? h.toFixed(1) : Math.round(h)) + "h"
  }
  var mins = Math.floor(ms / MINUTE)
  if (mins < 1)
    return Math.floor(ms / 1000) + "s"
  var hh = Math.floor(mins / 60)
  var mm = mins % 60
  if (hh === 0)
    return mm + "m"
  return hh + "h " + mm + "m"
}

// Running timers: 1:02:03 / 4:05.
function fmtElapsed(ms) {
  var s = Math.max(0, Math.floor(ms / 1000))
  var h = Math.floor(s / 3600)
  var m = Math.floor((s % 3600) / 60)
  var sec = s % 60
  return (h > 0 ? h + ":" + pad(m) : m) + ":" + pad(sec)
}

// For event rows: duration with "sec" for short stretches, like the reference.
function fmtEvent(ms, format) {
  if (ms < MINUTE)
    return Math.max(0, Math.round(ms / 1000)) + " sec"
  if (format === "hm" || !format) {
    var mins = Math.round(ms / MINUTE)
    return Math.floor(mins / 60) + "h " + (mins % 60) + "m"
  }
  return fmt(ms, format)
}

var DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
var MONTH_NAMES = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

function shortMonth(i) {
  return MONTH_NAMES[i].slice(0, 3)
}

function clock(ms) {
  var d = new Date(ms)
  var h = d.getHours()
  var ampm = h < 12 ? "AM" : "PM"
  h = h % 12
  if (h === 0)
    h = 12
  return h + ":" + pad(d.getMinutes()) + " " + ampm
}

// "Saturday, Sep 19"
function dayTitle(ms) {
  var d = new Date(ms)
  return DAY_NAMES[d.getDay()] + ", " + shortMonth(d.getMonth()) + " " + d.getDate()
}

// ---- Queries ---------------------------------------------------------------------

// Finished events plus running timers as open-ended events up to `now`.
function allSpans(data, now) {
  var out = data.events.slice()
  data.running.forEach(function (r) {
    out.push({ id: "running:" + r.activity, activity: r.activity, start: r.start, end: Math.max(r.start, now), running: true })
  })
  return out
}

// Overlap of [start, end) with [from, to).
function clip(start, end, from, to) {
  return Math.max(0, Math.min(end, to) - Math.max(start, from))
}

// Time per activity in [from, to): [{ id, name, color, ms, count, share }],
// biggest first. `hidden` ids are left out.
function totals(data, now, from, to, hidden) {
  var hide = {}
  ;(hidden || []).forEach(function (h) { hide[h] = true })
  var by = {}
  var sum = 0
  allSpans(data, now).forEach(function (e) {
    if (hide[e.activity])
      return
    var ms = clip(e.start, e.end, from, to)
    if (ms <= 0)
      return
    if (!by[e.activity])
      by[e.activity] = { ms: 0, count: 0 }
    by[e.activity].ms += ms
    by[e.activity].count++
    sum += ms
  })
  var rows = []
  for (var id in by) {
    var a = activityById(data, id)
    if (a)
      rows.push({ id: id, name: a.name, color: a.color, ms: by[id].ms, count: by[id].count, share: sum > 0 ? by[id].ms / sum : 0 })
  }
  rows.sort(function (x, y) { return y.ms - x.ms })
  return rows
}

function sumMs(rows) {
  var s = 0
  rows.forEach(function (r) { s += r.ms })
  return s
}

// Pie slices from totals rows: adds startFrac and sweepFrac.
function pieSlices(rows) {
  var at = 0
  return rows.map(function (r) {
    var s = Object.assign({}, r, { startFrac: at, sweepFrac: r.share })
    at += r.share
    return s
  })
}

// The period on screen in the timeline. kind: "day" | "week" | "month" | "year";
// offset 0 is the current one, 1 the one before, and so on.
function periodRange(kind, offset, now, weekStart) {
  var d = new Date(now)
  var from, to, label
  if (kind === "day") {
    from = addDays(startOfDay(now), -offset)
    to = addDays(from, 1)
    label = offset === 0 ? "Today" : offset === 1 ? "Yesterday" : dayTitle(from)
  } else if (kind === "week") {
    from = addDays(startOfWeek(now, weekStart), -7 * offset)
    to = addDays(from, 7)
    var last = new Date(addDays(to, -1))
    var f = new Date(from)
    label = shortMonth(f.getMonth()) + " " + f.getDate() + " – " + (last.getMonth() !== f.getMonth() ? shortMonth(last.getMonth()) + " " : "") + last.getDate()
  } else if (kind === "month") {
    var m = new Date(d.getFullYear(), d.getMonth() - offset, 1)
    from = m.getTime()
    to = new Date(m.getFullYear(), m.getMonth() + 1, 1).getTime()
    label = MONTH_NAMES[m.getMonth()] + " " + m.getFullYear()
  } else {
    from = new Date(d.getFullYear() - offset, 0, 1).getTime()
    to = new Date(d.getFullYear() - offset + 1, 0, 1).getTime()
    label = "" + (d.getFullYear() - offset)
  }
  return { from: from, to: to, label: label }
}

// Ticks for the timeline axis of a period: [{ frac, label }].
function axisTicks(kind, from, to) {
  var out = []
  var span = to - from
  if (kind === "day") {
    for (var h = 0; h <= 24; h += 6)
      out.push({ frac: h / 24, label: h === 24 ? "" : (h === 0 ? "12a" : h < 12 ? h + "a" : h === 12 ? "12p" : (h - 12) + "p") })
  } else if (kind === "week") {
    for (var i = 0; i < 7; i++) {
      var t = addDays(from, i)
      out.push({ frac: (t - from) / span, label: DAY_NAMES[new Date(t).getDay()].slice(0, 2) })
    }
  } else if (kind === "month") {
    var days = Math.round(span / DAY)
    for (var k = 0; k < days; k += 7)
      out.push({ frac: (addDays(from, k) - from) / span, label: "" + (k + 1) })
  } else {
    var y = new Date(from).getFullYear()
    for (var q = 0; q < 4; q++) {
      var qt = new Date(y, q * 3, 1).getTime()
      out.push({ frac: (qt - from) / span, label: "Q" + (q + 1) })
    }
  }
  return out
}

// Blocks for the timeline strip: [{ activity, color, startFrac, widthFrac }].
function strip(data, now, from, to, hidden) {
  var hide = {}
  ;(hidden || []).forEach(function (h) { hide[h] = true })
  var span = to - from
  var out = []
  allSpans(data, now).forEach(function (e) {
    if (hide[e.activity] || clip(e.start, e.end, from, to) <= 0)
      return
    var a = activityById(data, e.activity)
    if (!a)
      return
    var s = Math.max(e.start, from)
    var en = Math.min(e.end, to)
    out.push({ activity: e.activity, color: a.color, startFrac: (s - from) / span, widthFrac: (en - s) / span })
  })
  return out
}

// The events log: newest first, grouped by the day they started.
// [{ key, title, count, events: [{ id, activity, name, color, start, end, running }] }]
function eventLog(data, now, limitDays) {
  var spans = allSpans(data, now).slice().sort(function (a, b) { return b.start - a.start })
  var groups = []
  var byKey = {}
  spans.forEach(function (e) {
    var a = activityById(data, e.activity)
    if (!a)
      return
    var key = dayKey(new Date(e.start))
    if (!byKey[key]) {
      if (limitDays && groups.length >= limitDays)
        return
      byKey[key] = { key: key, title: dayTitle(e.start), count: 0, events: [] }
      groups.push(byKey[key])
    }
    byKey[key].count++
    byKey[key].events.push({ id: e.id, activity: e.activity, name: a.name, color: a.color, start: e.start, end: e.end, running: e.running === true })
  })
  return groups
}

// ---- Goals -----------------------------------------------------------------------

// [{ goal, name, color, doneMs, targetMs, ratio, reached, over }]
function goalStatus(data, now) {
  var day = startOfDay(now)
  var week = startOfWeek(now, data.settings.weekStart)
  var out = []
  data.goals.forEach(function (g) {
    var a = activityById(data, g.activity)
    if (!a || a.archived)
      return
    var from = g.period === "week" ? week : day
    var to = g.period === "week" ? addDays(week, 7) : addDays(day, 1)
    var done = 0
    allSpans(data, now).forEach(function (e) {
      if (e.activity === g.activity)
        done += clip(e.start, e.end, from, to)
    })
    var target = g.minutes * MINUTE
    out.push({
      goal: g, name: a.name, color: a.color, doneMs: done, targetMs: target,
      ratio: Math.min(1, target > 0 ? done / target : 0),
      reached: done >= target,
      over: g.kind === "atMost" && done > target
    })
  })
  return out
}

// ---- Insights for the Tracking tab's summary card ----------------------------------

function todaySummary(data, now) {
  var from = startOfDay(now)
  var rows = totals(data, now, from, addDays(from, 1), [])
  return { total: sumMs(rows), top: rows.length ? rows[0] : null, rows: rows }
}

// ---- Export -----------------------------------------------------------------------

function csvCell(v) {
  var s = String(v)
  return /[",\n]/.test(s) ? '"' + s.replace(/"/g, '""') + '"' : s
}

function isoLocal(ms) {
  var d = new Date(ms)
  return dayKey(d) + " " + pad(d.getHours()) + ":" + pad(d.getMinutes()) + ":" + pad(d.getSeconds())
}

function toCsv(data, now) {
  var lines = ["activity,start,end,duration_minutes"]
  allSpans(data, now).slice().sort(function (a, b) { return a.start - b.start }).forEach(function (e) {
    var a = activityById(data, e.activity)
    if (!a)
      return
    lines.push([csvCell(a.name), isoLocal(e.start), e.running ? "" : isoLocal(e.end), ((e.end - e.start) / MINUTE).toFixed(1)].join(","))
  })
  return lines.join("\n") + "\n"
}
