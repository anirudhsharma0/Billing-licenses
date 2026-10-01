/**
 * Convert numbers to Indian Currency Words (Lakhs, Crores, Rupees, Paise)
 * Standard Indian GST / Tally format
 */

const units = [
  "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
  "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
  "Seventeen", "Eighteen", "Nineteen"
];

const tens = [
  "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
];

function twoDigits(n) {
  if (n === 0) return "";
  if (n < 20) return units[n];
  const t = Math.floor(n / 10);
  const u = n % 10;
  return (tens[t] + (u ? " " + units[u] : "")).trim();
}

function threeDigits(n) {
  const h = Math.floor(n / 100);
  const rem = n % 100;
  let str = "";
  if (h > 0) {
    str += units[h] + " Hundred";
  }
  if (rem > 0) {
    str += (str ? " and " : "") + twoDigits(rem);
  }
  return str.trim();
}

/**
 * Converts a positive integer to Indian words
 * Grouping: ... Crore, Lakh, Thousand, Hundred ...
 */
function convertIntegerToIndianWords(num) {
  if (num === 0) return "Zero";

  const crore = Math.floor(num / 10000000);
  num %= 10000000;

  const lakh = Math.floor(num / 100000);
  num %= 100000;

  const thousand = Math.floor(num / 1000);
  num %= 1000;

  const remainder = num;

  const parts = [];

  if (crore > 0) {
    parts.push(convertIntegerToIndianWords(crore) + " Crore");
  }
  if (lakh > 0) {
    parts.push(twoDigits(lakh) + " Lakh");
  }
  if (thousand > 0) {
    parts.push(twoDigits(thousand) + " Thousand");
  }
  if (remainder > 0) {
    parts.push(threeDigits(remainder));
  }

  return parts.join(" ");
}

/**
 * Main export: Formats amount in INR words
 * @param {number|string} amount - e.g. 15420.50
 * @param {string} prefix - default 'INR' or 'Indian Rupees'
 * @returns {string} e.g. "INR Fifteen Thousand Four Hundred Twenty and Paise Fifty Only"
 */
export function numberToWords(amount, prefix = "") {
  const pfx = prefix ? `${prefix.trim()} ` : "";
  if (amount === undefined || amount === null || isNaN(amount)) return `${pfx}Zero Only`.trim();

  const parsed = parseFloat(amount);
  if (parsed === 0) return `${pfx}Zero Only`.trim();

  const absolute = Math.abs(parsed);
  const rupees = Math.floor(absolute);
  const paise = Math.round((absolute - rupees) * 100);

  let result = convertIntegerToIndianWords(rupees);
  if (rupees === 0 && paise > 0) {
    result = "";
  }

  let words = pfx;
  if (result) {
    words += result;
  }

  if (paise > 0) {
    const paiseWords = twoDigits(paise);
    if (result) {
      words += ` and Paise ${paiseWords}`;
    } else {
      words += `Paise ${paiseWords}`;
    }
  }

  words += " Only";

  return words.replace(/\s+/g, " ").trim();
}

/**
 * Format currency with Indian Comma separators
 * e.g. 1250000.5 -> 12,50,000.50
 */
export function formatIndianCurrency(amount) {
  if (amount === undefined || amount === null || isNaN(amount)) return "0.00";
  const num = parseFloat(amount);
  return num.toLocaleString("en-IN", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
}
