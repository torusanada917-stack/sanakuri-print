// ==UserScript==
// @name         さなくり デジスマ予約票 無音印刷
// @namespace    sanakuri
// @version      1.2
// @description  予約確認画面に「予約して印刷」ボタン／チェックイン履歴の各行に「印刷」ボタン／当日詳細に「予約票を無音印刷」ボタンを追加。予約票PDFをタブで開かずにOKIへA5で印刷する
// @match        https://console.digikar-smart.jp/*
// @homepageURL  https://github.com/torusanada917-stack/sanakuri-print
// @updateURL    https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_digisma.user.js
// @downloadURL  https://raw.githubusercontent.com/torusanada917-stack/sanakuri-print/main/sanakuri_digisma.user.js
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function () {
  'use strict';

  const PAGE_CODE = function () {
    // ===== 設定（変えるのはここだけ）=====
    const FILE_PREFIX = 'sanakuri_yoyaku_';   // 常駐(watcher)が拾うファイル名の先頭。config.txt の PREFIX=sanakuri_ に含まれる
    const FILE_EXT = '.kpdf';                  // Chrome/Acrobat が勝手に開かないよう .pdf 以外にする（中身はPDF）
    const FORCE_UNCHECK_PRINT = true;          // 予約確認画面の「予約票を印刷」チェックを常に外しておく
    // =====================================

    if (window.__sanakuriDigismaVersion) return;
    window.__sanakuriDigismaVersion = '1.2';

    const FLAG_TTL_MS = 20000;
    let mode = null, modeAt = 0;
    function setMode(m) { mode = m; modeAt = Date.now(); }
    function modeActive() { return mode === 'print' && (Date.now() - modeAt < FLAG_TTL_MS); }
    function clearMode() { mode = null; }

    // ---- blob URL → Blob の対応を覚えておく ----
    const blobMap = new Map();
    const realCreateObjectURL = URL.createObjectURL;
    URL.createObjectURL = function (obj) {
      const u = realCreateObjectURL.call(URL, obj);
      try { if (obj && obj.type === 'application/pdf') { blobMap.set(u, obj); setTimeout(() => blobMap.delete(u), 120000); } } catch (e) {}
      return u;
    };

    // ---- 予約票PDFを別タブで開くリンクのクリックを横取り ----
    const realClick = HTMLAnchorElement.prototype.click;
    HTMLAnchorElement.prototype.click = function () {
      try {
        if (modeActive() && this.target === '_blank' && !this.download && String(this.href).startsWith('blob:')) {
          const blob = blobMap.get(this.href);
          if (blob) {
            clearMode();
            const a = document.createElement('a');
            a.href = this.href;
            a.download = FILE_PREFIX + stamp() + FILE_EXT;
            a.style.display = 'none';
            document.body.appendChild(a);
            realClick.call(a);
            setTimeout(() => a.remove(), 15000);
            toast('予約票の印刷データを送りました');
            return;
          }
        }
      } catch (e) { console.error('[sanakuri-digisma]', e); }
      return realClick.call(this);
    };

    // ---- 画面要素の探索 ----
    const modals = () => [...document.querySelectorAll('.bg-system-modal')];
    const btnByText = (root, text) => [...root.querySelectorAll('button')].find(b => b.textContent.trim() === text);
    const checkboxByLabel = (root, label) => [...root.querySelectorAll('input[type=checkbox]')].find(c => ((c.closest('label') || c.parentElement || {}).innerText || '').includes(label));

    function styleLike(btn, ref, extraCss) {
      btn.type = 'button';
      btn.className = ref.className;
      btn.style.cssText = (extraCss || '');
    }

    // (1) 予約確認画面：「予約して印刷」ボタン、チェックは常に外す
    function enhanceConfirm(m) {
      if (m.dataset.sanakuriConfirm) return;
      const txt = m.innerText || '';
      if (!txt.includes('予約確認') || !txt.includes('予約票を印刷')) return;
      const reserveBtn = btnByText(m, '予約');
      const cb = checkboxByLabel(m, '予約票を印刷');
      if (!reserveBtn || !cb) return;
      m.dataset.sanakuriConfirm = '1';
      if (FORCE_UNCHECK_PRINT && cb.checked) cb.click();

      const btn = document.createElement('button');
      styleLike(btn, reserveBtn, 'margin-right:8px;background:#1565c0;border-color:#1565c0;color:#fff;');
      btn.textContent = '🖨 予約して印刷';
      btn.title = '予約を確定し、予約票をOKIからA5で無音印刷（タブは開かない）';
      btn.addEventListener('click', (e) => {
        e.preventDefault(); e.stopPropagation();
        if (reserveBtn.disabled) return;
        if (!cb.checked) cb.click();
        setMode('print');
        setTimeout(() => reserveBtn.click(), 150);
      });
      reserveBtn.parentElement.insertBefore(btn, reserveBtn);
    }

    // (2) 当日詳細：「予約票を無音印刷」ボタン（本来の「予約票印刷」の隣）
    function enhanceDetail(m) {
      const printBtn = btnByText(m, '予約票印刷');
      if (!printBtn || m.querySelector('.sanakuri-detail-print')) return;
      const btn = document.createElement('button');
      styleLike(btn, printBtn, 'margin-top:6px;background:#1565c0;border-color:#1565c0;color:#fff;');
      btn.className += ' sanakuri-detail-print';
      btn.textContent = '🖨 予約票を無音印刷';
      btn.title = '予約票をOKIからA5で無音印刷（タブは開かない）';
      btn.addEventListener('click', (e) => {
        e.preventDefault(); e.stopPropagation();
        setMode('print');
        printBtn.click();
      });
      printBtn.parentElement.insertBefore(btn, printBtn.nextSibling);
    }

    // (3) チェックイン履歴：各行に「印刷」ボタン
    function enhanceHistory(m) {
      const table = [...m.querySelectorAll('table')].find(t => [...t.querySelectorAll('th')].some(th => th.innerText.trim() === '詳細'));
      if (!table) return;
      for (const tr of table.querySelectorAll('tbody tr, tr')) {
        if (tr.querySelector('.sanakuri-row-print')) continue;
        const detailBtn = tr.querySelector('button[aria-label="患者詳細を開く"]');
        if (!detailBtn) continue;
        if (/取消済/.test(tr.innerText)) continue;
        const cell = detailBtn.closest('td') || detailBtn.parentElement;
        cell.style.display = 'flex'; cell.style.alignItems = 'center'; cell.style.gap = '6px'; cell.style.height = '54px';
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = 'sanakuri-row-print';
        btn.textContent = '🖨';
        btn.title = 'この予約の予約票をOKIからA5で無音印刷';
        btn.style.cssText = 'width:36px;height:36px;border-radius:4px;border:none;background:#1565c0;color:#fff;font-size:16px;cursor:pointer;display:flex;align-items:center;justify-content:center;flex:none;';
        btn.addEventListener('click', async (e) => {
          e.preventDefault(); e.stopPropagation();
          btn.disabled = true; btn.textContent = '…';
          try {
            const before = modals().length;
            detailBtn.click();
            const newModal = await waitFor(() => { const ms = modals(); return ms.length > before ? ms[ms.length - 1] : null; }, 6000);
            if (!newModal) throw new Error('詳細画面が開きませんでした');
            const pb = await waitFor(() => btnByText(newModal, '予約票印刷'), 6000);
            if (!pb) throw new Error('予約票印刷ボタンが見つかりません');
            setMode('print');
            pb.click();
            await waitFor(() => !modeActive(), 10000);   // 横取り完了（mode がクリアされる）を待つ
            const closeBtn = btnByText(newModal, '閉じる');
            if (closeBtn) closeBtn.click();
          } catch (err) {
            console.error('[sanakuri-digisma]', err);
            toast('印刷できませんでした：' + err.message, true);
          } finally {
            clearMode();
            btn.disabled = false; btn.textContent = '🖨';
          }
        });
        cell.insertBefore(btn, cell.firstChild);
      }
    }

    function waitFor(fn, timeoutMs) {
      return new Promise((resolve) => {
        const t0 = Date.now();
        const tick = () => { let v = null; try { v = fn(); } catch (e) {} if (v) return resolve(v); if (Date.now() - t0 > timeoutMs) return resolve(null); setTimeout(tick, 150); };
        tick();
      });
    }

    let scheduled = false;
    function scan() {
      scheduled = false;
      for (const m of modals()) { enhanceConfirm(m); enhanceDetail(m); enhanceHistory(m); }
    }
    const mo = new MutationObserver(() => { if (!scheduled) { scheduled = true; setTimeout(scan, 100); } });
    const start = () => { mo.observe(document.body, { childList: true, subtree: true }); scan(); };
    if (document.body) start(); else document.addEventListener('DOMContentLoaded', start);

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
