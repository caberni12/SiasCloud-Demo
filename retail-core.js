/* Unidad base de inventario = unidad base de precio. No se mezclan variantes. */
(function (root, factory) {
  const api = factory();
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.SiasRetailCore = api;
})(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  'use strict';
  const normalizeUnit = value => ({ G: 'GR', GRAMOS: 'GR', KILOGRAMOS: 'KG', UNIDAD: 'UN', UNID: 'UN', UND: 'UN' }[String(value || 'UN').toUpperCase()] || String(value || 'UN').toUpperCase());
  function positive(value, label) {
    const n = Number(value);
    if (!Number.isFinite(n) || n <= 0 || n > 100000000) throw new Error(`${label}: ingresa un valor mayor que cero`);
    return n;
  }
  function unitFactor(product, unit) {
    const base = normalizeUnit(product.unit), selected = normalizeUnit(unit);
    if (selected === base) return 1;
    if (selected === 'GR' && base === 'KG') return 0.001;
    if (selected === 'KG' && base === 'GR') return 1000;
    if (selected === 'CAJA') return positive(product.pack_quantity, 'Cantidad por caja');
    if (selected === 'PALLET') return positive(product.pack_quantity, 'Cantidad por caja') * positive(product.pallet_boxes, 'Cajas por pallet');
    throw new Error(`No puedes convertir ${selected} a ${base}`);
  }
  function toBase(product, quantity, unit) {
    const n = positive(quantity, 'Cantidad') * unitFactor(product, unit);
    if (!Number.isFinite(n) || n > 1000000) throw new Error('Cantidad fuera de rango');
    const result = Math.round((n + Number.EPSILON) * 10000) / 10000;
    if (result < 0.0001) throw new Error('La cantidad mínima es 0,0001 de la unidad base');
    if (normalizeUnit(product.unit) === 'UN' && product.fractional !== true && Math.abs(result - Math.round(result)) > 0.000001) throw new Error('Este producto se vende en unidades enteras');
    return result;
  }
  function addCapture(lines, product, quantity, unit, price) {
    const baseQty = toBase(product, quantity, unit), amount = Number(price ?? product.price);
    if (!Number.isFinite(amount) || amount < 0) throw new Error('Precio inválido');
    const next = lines.map(x => ({ ...x }));
    const found = next.find(x => x.product_id === product.id);
    if (found) {
      if (Number(found.unit_price) !== amount) throw new Error('El precio cambió: actualiza la línea antes de continuar');
      found.quantity = Math.round((found.quantity + baseQty) * 10000) / 10000;
      if (found.quantity > 1000000) throw new Error('Cantidad fuera de rango');
    } else next.push({ product_id: product.id, name: product.name, sku: product.sku, unit: normalizeUnit(product.unit), quantity: baseQty, unit_price: amount, tax_rate:Number(product.tax_rate??19), exempt:product.exempt===true, fractional:product.fractional===true });
    return next;
  }
  function totals(lines) {
    const total = lines.reduce((s, x) => s + Math.round(Number(x.quantity) * Number(x.unit_price)), 0);
    if (!Number.isSafeInteger(total) || total < 0) throw new Error('Total fuera de rango');
    return total;
  }
  function settlement(total, payments, credits) {
    const sum = entries => entries.reduce((s, x) => {
      const n = Number(x.amount);
      if (!Number.isSafeInteger(n) || n <= 0) throw new Error('Los pagos deben ser montos enteros mayores que cero');
      return s + n;
    }, 0);
    const paid = sum(payments), used = sum(credits);
    if (paid + used !== total) throw new Error('Los pagos y créditos deben cubrir exactamente el total');
    return { paid, used, total };
  }
  function parseCsv(text) {
    const source = String(text).replace(/^\uFEFF/, '');
    let quoted = false, semicolons = 0, commas = 0;
    for (const ch of source.slice(0, 5000)) { if (ch === '"') quoted = !quoted; else if (!quoted) { if (ch === ';') semicolons++; if (ch === ',') commas++; } }
    const delimiter = semicolons >= commas ? ';' : ',', rows = [];
    let row = [], cell = ''; quoted = false;
    for (let i = 0; i < source.length; i++) {
      const ch = source[i];
      if (ch === '"') { if (quoted && source[i + 1] === '"') { cell += '"'; i++; } else quoted = !quoted; }
      else if (!quoted && ch === delimiter) { row.push(cell); cell = ''; }
      else if (!quoted && (ch === '\n' || ch === '\r')) { if (ch === '\r' && source[i + 1] === '\n') i++; row.push(cell); if (row.some(v => v.trim())) rows.push(row); row = []; cell = ''; }
      else cell += ch;
    }
    if (quoted) throw new Error('El CSV tiene comillas sin cerrar');
    row.push(cell); if (row.some(v => v.trim())) rows.push(row);
    return rows;
  }
  function rcvRows(text) {
    const rows = parseCsv(text), norm = v => String(v).normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]/g, '');
    const header = rows.findIndex(r => r.some(v => /^tipodoc/.test(norm(v))) && r.some(v => norm(v) === 'folio'));
    if (header < 0) throw new Error('No se encontró el encabezado RCV: Tipo Doc y Folio');
    const fields = rows[header].map(norm), field = (r, names, required = false) => { const index = fields.findIndex(v => names.includes(v)); if (index < 0 && required) throw new Error('Falta columna: ' + names[0]); return index < 0 ? '' : r[index] || ''; };
    return rows.slice(header + 1).filter(r => r.length > 2).map((r, i) => {
      const type = Number(field(r, ['tipodoc','tipodocumento','tipodte'], true));
      const amount = names => { const raw = field(r, names).trim().replaceAll('.', '').replace(',', '.'); const n = raw === '' ? 0 : Number(raw); if (!Number.isSafeInteger(n) || n < 0 && type !== 61) throw new Error('Monto inválido en fila ' + (header + i + 2)); return Math.abs(n); };
      let date = field(r, ['fechadocto','fechadocumento','fechaemision'], true).trim(); const parts = date.match(/^(\d{2})[/-](\d{2})[/-](\d{4})$/); if (parts) date = `${parts[3]}-${parts[2]}-${parts[1]}`;
      if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !Number.isFinite(Date.parse(date)) || new Date(date).toISOString().slice(0, 10) !== date) throw new Error('Fecha inválida en fila ' + (header + i + 2));
      const result = { document_type: type, folio: field(r, ['folio'], true).trim(), rut: field(r, ['rutproveedor','rutcliente','rutreceptor','rut'], true).toUpperCase().replace(/[^0-9K]/g, ''), legal_name: field(r, ['razonsocial','razonsocialproveedor','razonsocialcliente']), issue_date: date, net: amount(['montoneto']), exempt: amount(['montoexento']), tax: amount(['montoivarecuperable','montoiva']), total: amount(['montototal']) };
      if (!Number.isSafeInteger(type) || type <= 0 || !result.folio || !result.rut) throw new Error('Documento inválido en fila ' + (header + i + 2));
      return result;
    });
  }
  return { normalizeUnit, unitFactor, toBase, addCapture, totals, settlement, parseCsv, rcvRows };
});
