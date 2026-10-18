// ==UserScript==
// @name         さなくり 会計PDF 無音印刷
// @namespace    sanakuri
// @version      1.5
// @description  「保存して印刷」(F9) → 保存＋無音印刷／「保存のみ」 → 保存だけ（印刷もタブもなし）／「保存」 → 従来どおり保存＋PDFタブ表示
// @match        https://digikar.jp/*
// @homepageURL  https://github.com/torusanada917-stack/sanakuri-print
// @updateURL    https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_kaikei.user.js
// @downloadURL  https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_kaikei.user.js
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function () {
  'use strict';

  // ページ本体（デジカルのJSと同じ場所）で動かすコード。Tampermonkeyの実行環境に関係なく window.open を確実に横取りするため、
  // <script> として注入する。
  const PAGE_CODE = function () {
    // ===== 設定（変えるのはここだけ）=====
    const PRINT_KEY = 'F9';              // 保存＋無音印刷 のキー
    const NORMAL_SAVE_OPENS_TAB = true;  // true: デジカル本来の「保存」は従来どおりPDFタブを開く（OKI故障時などはここから手動印刷）
    const FILE_PREFIX = 'sanakuri_kaikei_'; // ダウンロードするファイル名の先頭（watcher の config.txt と合わせる）
    const FILE_EXT = '.kpdf';               // 拡張子。.pdf にしないことで Chrome/Acrobat が勝手に開くのを防ぐ（中身はPDF）
    // =====================================

    if (window.__sanakuriVersion) return;
    window.__sanakuriVersion = '1.5';

    const PDF_RE = /\/api\/rece\/accounts\/\d+\/pdf\/reports/;
    const FLAG_TTL_MS = 20000;
    let mode = null, modeAt = 0; // 'print' | 'tab' | 'none'

    function setMode(m) { mode = m; modeAt = Date.now(); }
    function takeMode() { const m = (Date.now() - modeAt < FLAG_TTL_MS) ? mode : null; mode = null; return m; }
    function fakeWindow() { return { focus() {}, close() {}, blur() {}, closed: false, location: { href: '' }, document: { write() {}, close() {} } }; }

    // ---- window.open を横取り：会計PDFのときだけ分岐 ----
    const realOpen = window.open;
    window.open = function (url, ...rest) {
      try {
        const s = String(url || '');
        if (PDF_RE.test(s)) {
          const m = takeMode();
          if (m === 'print') { downloadForPrint(s); return fakeWindow(); }
          if (m === 'none') { toast('会計を保存しました（印刷なし）'); return fakeWindow(); }
          if (m === 'tab' || NORMAL_SAVE_OPENS_TAB) return realOpen.call(window, url, ...rest);
          toast('会計を保存しました（印刷なし）');
          return fakeWindow();
        }
      } catch (e) { console.error('[sanakuri]', e); }
      return realOpen.call(window, url, ...rest);
    };

    // ---- PDFを取得してダウンロードフォルダへ（watcher が拾って印刷）----
    async function downloadForPrint(url) {
      try {
        const u = new URL(url, location.href);
        const id = (u.pathname.match(/accounts\/(\d+)/) || [])[1] || 'x';
        const r = await fetch(u.href, { credentials: 'same-origin' });
        if (!r.ok) throw new Error('HTTP ' + r.status);
        const blob = await r.blob();
        if (blob.size < 100) throw new Error('empty pdf');
        const a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = FILE_PREFIX + id + '_' + stamp() + FILE_EXT;
        a.style.display = 'none';
        document.body.appendChild(a);
        a.click();
        setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 15000);
        toast('印刷データを送りました');
      } catch (e) {
        console.error('[sanakuri]', e);
        toast('印刷データの取得に失敗したので、PDFをタブで開きます', true);
        realOpen.call(window, url);
      }
    }

    function findSave(dlg) { return [...dlg.querySelectorAll('button')].find(b => b.textContent.trim() === '保存'); }

    // ---- F9 / Shift+F9：会計画面が開いている時だけ反応 ----
    document.addEventListener('keydown', (e) => {
      if (e.key !== PRINT_KEY) return;
      const dlg = document.querySelector('.dk-accounts-modal');
      if (!dlg) return;
      const save = findSave(dlg);
      if (!save || save.disabled) return;
      e.preventDefault(); e.stopPropagation();
      setMode(e.shiftKey ? 'tab' : 'print');
      save.click();
    }, true);

    // ---- 会計画面にボタンを追加（保存ボタンの左）：「保存して印刷」「保存のみ」。本来の「保存」はそのまま ----
    function makeButton(save, label, cssExtra, title, onClick) {
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.className = save.className + ' sanakuri-btn';
      for (const k of Object.keys(save.dataset)) btn.dataset[k] = save.dataset[k];
      btn.textContent = label;
      btn.style.cssText = 'margin-right:8px;' + cssExtra;
      btn.title = title;
      btn.addEventListener('click', (e) => {
        e.preventDefault(); e.stopPropagation();
        if (save.disabled) return;
        onClick(e);
        save.click();
      });
      return btn;
    }
    function addButton() {
      const dlg = document.querySelector('.dk-accounts-modal');
      if (!dlg || dlg.querySelector('.sanakuri-btn')) return;
      const save = findSave(dlg);
      if (!save) return;

      const printBtn = makeButton(save, '🖨 保存して印刷 (' + PRINT_KEY + ')', 'background:#1565c0;border-color:#1565c0;',
        'クリック：保存してA5で無音印刷　／　Shift+クリック：保存してPDFをタブ表示',
        (e) => setMode(e.shiftKey ? 'tab' : 'print'));
      const noneBtn = makeButton(save, '保存のみ', 'background:#616161;border-color:#616161;',
        '保存だけ行い、印刷もPDF表示もしない（明細が不要な時・デジスマ送付済みの時）',
        () => setMode('none'));
      save.parentElement.insertBefore(printBtn, save);
      save.parentElement.insertBefore(noneBtn, save);
      save.title = 'デジカル本来の保存：保存してPDFを別タブに表示（手動で印刷する時はこちら）';
    }
    const mo = new MutationObserver(addButton);
    const startObserve = () => { mo.observe(document.body, { childList: true, subtree: true }); addButton(); };
    if (document.body) startObserve(); else document.addEventListener('DOMContentLoaded', startObserve);

    // ---- 小さな通知 ----
    function toast(msg, isError) {
      const d = document.createElement('div');
      d.textContent = msg;
      d.style.cssText = 'position:fixed;right:16px;bottom:16px;z-index:2147483647;padding:10px 16px;border-radius:6px;font-size:14px;color:#fff;box-shadow:0 2px 8px rgba(0,0,0,.3);background:' + (isError ? '#c62828' : '#2e7d32') + ';opacity:0;transition:opacity .2s;';
      document.body.appendChild(d);
      requestAnimationFrame(() => { d.style.opacity = '1'; });
      setTimeout(() => { d.style.opacity = '0'; setTimeout(() => d.remove(), 300); }, isError ? 5000 : 2500);
    }

    function stamp() {
      const n = new Date(), p = (x) => String(x).padStart(2, '0');
      return n.getFullYear() + p(n.getMonth() + 1) + p(n.getDate()) + '_' + p(n.getHours()) + p(n.getMinutes()) + p(n.getSeconds());
    }
  };

  const s = document.createElement('script');
  s.textContent = '(' + PAGE_CODE.toString() + ')();';
  (document.head || document.documentElement).appendChild(s);
  s.remove();
})();
