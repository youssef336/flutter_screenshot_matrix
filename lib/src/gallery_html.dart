// Pure Dart (no Flutter imports): shared by the test helper and the
// `dart run flutter_screenshot_matrix:gallery` command.

import 'dart:convert';

import 'manifest.dart';

/// Renders the self-contained gallery page for [manifest].
///
/// The page has no external dependencies: styles, script and data are inline,
/// and screenshots are referenced by their path relative to the page.
String renderGalleryHtml(
  Manifest manifest, {
  String title = 'Screenshot matrix',
}) {
  // `<` only ever appears inside JSON strings, where `\u003c` is equivalent;
  // escaping it keeps the data from closing the <script> element.
  final String data = const JsonEncoder()
      .convert(manifest.toJson())
      .replaceAll('<', r'\u003c');
  final String safeTitle = htmlEscape.convert(title);
  return _template.replaceAllMapped(
    RegExp(r'\{\{(TITLE|DATA)\}\}'),
    (Match m) => m[1] == 'TITLE' ? safeTitle : data,
  );
}

const String _template = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="generator" content="flutter_screenshot_matrix">
<title>{{TITLE}}</title>
<style>
:root {
  --bg: #f6f7f9; --panel: #ffffff; --text: #16181d; --muted: #646b78;
  --border: #dde1e7; --chip: #eef0f4; --chip-on: #16181d; --chip-on-text: #ffffff;
  --error: #d92d20; --error-bg: #fee4e2; --warn: #b54708; --warn-bg: #fef0c7;
  --ok: #067647; --shadow: 0 1px 2px rgba(16,24,40,.06), 0 1px 3px rgba(16,24,40,.1);
  color-scheme: light;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #0f1115; --panel: #171a21; --text: #e9ecf1; --muted: #9aa3b2;
    --border: #2a2f3a; --chip: #232833; --chip-on: #e9ecf1; --chip-on-text: #0f1115;
    --error: #f97066; --error-bg: #3b1513; --warn: #fdb022; --warn-bg: #3a2a0c;
    --ok: #47cd89; --shadow: none;
    color-scheme: dark;
  }
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text);
  font: 14px/1.45 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
header { position: sticky; top: 0; z-index: 5; background: var(--panel);
  border-bottom: 1px solid var(--border); padding: 12px 16px; }
h1 { font-size: 18px; margin: 0 0 2px; }
.summary { color: var(--muted); font-size: 13px; }
.summary b.err { color: var(--error); } .summary b.warn { color: var(--warn); }
.filters { display: flex; flex-wrap: wrap; gap: 8px 18px; margin-top: 10px; align-items: center; }
.filter { display: flex; flex-wrap: wrap; gap: 4px; align-items: center; }
.filter > span { color: var(--muted); font-size: 12px; margin-inline-end: 2px; }
.chip { border: 1px solid var(--border); background: var(--chip); color: var(--text);
  border-radius: 999px; padding: 2px 10px; font: inherit; font-size: 12px; cursor: pointer; }
.chip[aria-pressed="true"] { background: var(--chip-on); color: var(--chip-on-text); border-color: var(--chip-on); }
.controls { display: flex; gap: 14px; align-items: center; font-size: 12px; color: var(--muted); }
.controls select, .controls input { font: inherit; }
main { padding: 16px; }
section { margin-bottom: 28px; }
section h2 { font-size: 15px; margin: 0 0 10px; display: flex; gap: 8px; align-items: baseline; }
section h2 small { color: var(--muted); font-weight: 400; }
.grid { display: flex; flex-wrap: wrap; gap: 14px; align-items: flex-start; }
.card { background: var(--panel); border: 1px solid var(--border); border-radius: 10px;
  padding: 8px; box-shadow: var(--shadow); }
.card.has-error { border-color: var(--error); }
.card img { display: block; border-radius: 6px; cursor: zoom-in; background: var(--chip); }
.meta { margin-top: 6px; font-size: 12px; max-width: 100%; }
.meta .line { color: var(--muted); }
.badges { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 4px; }
.badge { font-size: 11px; font-weight: 600; border-radius: 4px; padding: 1px 6px; }
.badge.error { background: var(--error-bg); color: var(--error); }
.badge.warn { background: var(--warn-bg); color: var(--warn); }
.badge.ok { color: var(--ok); padding-inline: 0; }
.empty { color: var(--muted); padding: 40px 0; text-align: center; }
dialog { border: 0; padding: 0; background: transparent; max-width: 96vw; max-height: 96vh; }
dialog::backdrop { background: rgba(0,0,0,.75); }
.lightbox { display: flex; gap: 16px; align-items: flex-start; background: var(--panel);
  color: var(--text); border-radius: 12px; padding: 14px; max-height: 94vh; }
.lightbox img { max-height: calc(94vh - 28px); max-width: 60vw; border-radius: 6px; }
.lightbox .info { width: 340px; max-height: calc(94vh - 28px); overflow: auto; font-size: 13px; }
.lightbox .info h3 { margin: 0 0 6px; font-size: 15px; }
.lightbox ul { padding-inline-start: 18px; }
.lightbox li { margin-bottom: 8px; }
.lightbox code { font-size: 11px; word-break: break-all; }
.lightbox pre { white-space: pre-wrap; font-size: 11px; max-height: 240px; overflow: auto;
  background: var(--chip); padding: 6px; border-radius: 6px; }
.close { float: right; }
@media (max-width: 700px) {
  .lightbox { flex-direction: column; }
  .lightbox img { max-width: 100%; max-height: 60vh; }
  .lightbox .info { width: auto; }
}
</style>
</head>
<body>
<header>
  <h1>{{TITLE}}</h1>
  <div class="summary" id="summary"></div>
  <div class="filters" id="filters"></div>
</header>
<main id="main"></main>
<dialog id="dialog"></dialog>
<script type="application/json" id="manifest">{{DATA}}</script>
<script>
(function () {
  'use strict';
  var manifest = JSON.parse(document.getElementById('manifest').textContent);
  var entries = manifest.entries || [];
  var dims = [
    { key: 'screen', label: 'Screen', get: function (e) { return e.screen; } },
    { key: 'device', label: 'Device', get: function (e) { return e.deviceName; } },
    { key: 'locale', label: 'Locale', get: function (e) { return e.locale; } },
    { key: 'theme', label: 'Theme', get: function (e) { return e.theme; } },
    { key: 'scale', label: 'Text', get: function (e) { return scaleLabel(e.textScale); } }
  ];
  var state = { off: {}, issuesOnly: false, groupBy: 'screen', zoom: 0.6 };
  dims.forEach(function (d) { state.off[d.key] = {}; });

  function scaleLabel(s) { var t = Number(s).toFixed(2).replace(/0$/, ''); return t + 'x'; }
  function el(tag, attrs, children) {
    var n = document.createElement(tag);
    Object.keys(attrs || {}).forEach(function (k) {
      if (k === 'text') n.textContent = attrs[k];
      else if (k === 'class') n.className = attrs[k];
      else if (k.indexOf('on') === 0) n.addEventListener(k.slice(2), attrs[k]);
      else n.setAttribute(k, attrs[k]);
    });
    (children || []).forEach(function (c) { if (c) n.appendChild(c); });
    return n;
  }
  function distinct(get) {
    var out = [];
    entries.forEach(function (e) { var v = get(e); if (out.indexOf(v) < 0) out.push(v); });
    return out;
  }
  function counts(e) {
    var c = { overflow: 0, exception: 0, golden: 0, textTruncated: 0 };
    (e.issues || []).forEach(function (i) { c[i.kind] = (c[i.kind] || 0) + 1; });
    return c;
  }
  function hasError(e) { var c = counts(e); return c.overflow + c.exception + c.golden > 0; }
  function hasIssue(e) { return (e.issues || []).length > 0; }

  function renderSummary() {
    var errors = entries.filter(hasError).length;
    var warns = entries.filter(function (e) { return hasIssue(e) && !hasError(e); }).length;
    var s = document.getElementById('summary');
    s.textContent = '';
    s.appendChild(document.createTextNode(entries.length + ' screenshots · ' +
      distinct(dims[0].get).length + ' screens · '));
    s.appendChild(el('b', { class: errors ? 'err' : '', text: errors + ' with errors' }));
    s.appendChild(document.createTextNode(' · '));
    s.appendChild(el('b', { class: warns ? 'warn' : '', text: warns + ' with warnings' }));
    if (manifest.generatedAt) {
      s.appendChild(document.createTextNode(' · ' + new Date(manifest.generatedAt).toLocaleString()));
    }
  }

  function renderFilters() {
    var box = document.getElementById('filters');
    box.textContent = '';
    dims.forEach(function (d) {
      var values = distinct(d.get);
      if (values.length < 2) return;
      var group = el('div', { class: 'filter' }, [el('span', { text: d.label })]);
      values.forEach(function (v) {
        group.appendChild(el('button', {
          class: 'chip', type: 'button', text: v,
          'aria-pressed': state.off[d.key][v] ? 'false' : 'true',
          onclick: function () { state.off[d.key][v] = !state.off[d.key][v]; render(); }
        }));
      });
      box.appendChild(group);
    });
    var only = el('input', { type: 'checkbox', id: 'only' });
    only.checked = state.issuesOnly;
    only.addEventListener('change', function () { state.issuesOnly = only.checked; render(); });
    var group = el('select', { id: 'group' });
    dims.forEach(function (d) {
      var o = el('option', { value: d.key, text: d.label });
      if (d.key === state.groupBy) o.selected = true;
      group.appendChild(o);
    });
    group.addEventListener('change', function () { state.groupBy = group.value; render(); });
    var zoom = el('input', { type: 'range', min: '0.25', max: '1.5', step: '0.05', value: String(state.zoom) });
    zoom.addEventListener('input', function () { state.zoom = Number(zoom.value); renderGrid(); });
    box.appendChild(el('div', { class: 'controls' }, [
      el('label', {}, [only, document.createTextNode(' issues only')]),
      el('label', {}, [document.createTextNode('group by '), group]),
      el('label', {}, [document.createTextNode('size '), zoom])
    ]));
  }

  function visible() {
    return entries.filter(function (e) {
      if (state.issuesOnly && !hasIssue(e)) return false;
      return dims.every(function (d) { return !state.off[d.key][d.get(e)]; });
    });
  }

  function badges(e) {
    var c = counts(e);
    var b = el('div', { class: 'badges' });
    if (c.overflow) b.appendChild(el('span', { class: 'badge error', text: 'overflow ×' + c.overflow }));
    if (c.exception) b.appendChild(el('span', { class: 'badge error', text: 'exception ×' + c.exception }));
    if (c.golden) b.appendChild(el('span', { class: 'badge error', text: 'golden mismatch' }));
    if (c.textTruncated) b.appendChild(el('span', { class: 'badge warn', text: 'truncated ×' + c.textTruncated }));
    if (!hasIssue(e)) b.appendChild(el('span', { class: 'badge ok', text: '✓' }));
    return b;
  }

  function card(e) {
    var ratio = e.devicePixelRatio || 1;
    var w = Math.round((e.imageWidth || e.logicalWidth * ratio) / ratio * state.zoom);
    var img = el('img', { src: e.file, loading: 'lazy', alt: e.id, width: String(w) });
    if (e.imageWidth && e.imageHeight) img.height = Math.round(w * e.imageHeight / e.imageWidth);
    img.addEventListener('click', function () { open(e); });
    var line = [e.deviceName, e.locale, e.theme, scaleLabel(e.textScale)];
    var meta = el('div', { class: 'meta', style: 'width:' + w + 'px' }, [
      state.groupBy === 'screen' ? null : el('div', { text: e.screen }),
      el('div', { class: 'line', text: line.join(' · ') }),
      badges(e)
    ]);
    return el('div', { class: 'card' + (hasError(e) ? ' has-error' : '') }, [img, meta]);
  }

  function renderGrid() {
    var main = document.getElementById('main');
    main.textContent = '';
    var list = visible();
    if (!list.length) { main.appendChild(el('div', { class: 'empty', text: 'Nothing matches the filters.' })); return; }
    var dim = dims.filter(function (d) { return d.key === state.groupBy; })[0];
    var keys = [];
    list.forEach(function (e) { var k = dim.get(e); if (keys.indexOf(k) < 0) keys.push(k); });
    keys.forEach(function (k) {
      var items = list.filter(function (e) { return dim.get(e) === k; });
      var bad = items.filter(hasError).length;
      var title = el('h2', {}, [document.createTextNode(k + ' '),
        el('small', { text: items.length + ' shots' + (bad ? ' · ' + bad + ' with errors' : '') })]);
      main.appendChild(el('section', {}, [title, el('div', { class: 'grid' }, items.map(card))]));
    });
  }

  function open(e) {
    var dialog = document.getElementById('dialog');
    dialog.textContent = '';
    var list = el('ul');
    (e.issues || []).forEach(function (i) {
      list.appendChild(el('li', {}, [
        el('span', { class: 'badge ' + (i.kind === 'textTruncated' ? 'warn' : 'error'), text: i.kind }),
        document.createTextNode(' ' + i.message),
        i.source ? el('div', {}, [el('code', { text: i.source })]) : null,
        i.details ? el('pre', { text: i.details }) : null
      ]));
    });
    var info = el('div', { class: 'info' }, [
      el('button', { class: 'chip close', type: 'button', text: 'Close', onclick: function () { dialog.close(); } }),
      el('h3', { text: e.screen }),
      el('div', { class: 'line', text: e.deviceName + ' (' + e.logicalWidth + '×' + e.logicalHeight +
        ' @' + e.devicePixelRatio + 'x, ' + e.platform + ')' }),
      el('div', { class: 'line', text: e.locale + (e.rtl ? ' (RTL)' : '') + ' · ' + e.theme +
        ' · text ' + scaleLabel(e.textScale) }),
      el('div', {}, [el('a', { href: e.file, target: '_blank', rel: 'noopener', text: e.file })]),
      (e.issues || []).length ? list : el('p', { class: 'badge ok', text: '✓ no issues' })
    ]);
    dialog.appendChild(el('div', { class: 'lightbox' }, [el('img', { src: e.file, alt: e.id }), info]));
    dialog.addEventListener('click', function (ev) { if (ev.target === dialog) dialog.close(); });
    dialog.showModal();
  }

  function render() { renderSummary(); renderFilters(); renderGrid(); }
  render();
})();
</script>
</body>
</html>
''';
