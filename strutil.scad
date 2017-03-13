// String utility functions.

function substr(s, off, len) = (len <= 0 || off >= len(s)) ? "" :
  off < 0 ? substr(s, 0, len+off) : str(s[off], substr(s, off+1, len-1));

// returns pos >= startpos which is starting location of needle
function indexof(haystack, needle, startpos=0) =
  (startpos > len(haystack) - len(needle)) ? -1 :
  substr(haystack, startpos, len(needle)) == needle ? startpos :
  indexof(haystack, needle, startpos + 1);

function startswith(s, prefix) =
  (substr(s, 0, len(prefix)) == prefix);

function endswith(s, suffix) =
  (substr(s, len(s) - len(suffix), len(s)) == suffix);

// returns pos < startpos which is the starting location of needle
function rindexof(haystack, needle, startpos=-1) =
  startpos < 0 ? rindexof(haystack, needle, len(haystack)) :
  startpos == 0 ? -1 :
  substr(haystack, startpos-1, len(needle)) == needle ? startpos-1 :
  rindexof(haystack, needle, startpos-1);

function digitat(str, i=0) = (i < 0 || i >= len(str)) ? -1 :
  str[i] == "0" ? 0 : str[i] == "1" ? 1 :
  str[i] == "2" ? 2 : str[i] == "3" ? 3 :
  str[i] == "4" ? 4 : str[i] == "5" ? 5 :
  str[i] == "6" ? 6 : str[i] == "7" ? 7 :
  str[i] == "8" ? 8 : str[i] == "9" ? 9 : -1;

// returns length of the number starting at pos
function numlen(str, pos=0, intonly=false, accum=0) =
  digitat(str, pos) >= 0 ? numlen(str, pos+1, intonly, accum+1) :
  (substr(str, pos, 1)=="." && !intonly) ? numlen(str, pos+1, true, accum+1) :
  accum;

// returns length of the number ending before pos
// (that is, the final char of the number is at pos-1, and if
// this function returns x, then substr(str, pos-x, x) will
// extract the full number).
function rnumlen(str, pos=-1, intonly=false, accum=0) =
  pos < 0 ? rnumlen(str, len(str), intonly, accum) :
  digitat(str, pos-1) >= 0 ? rnumlen(str, pos-1, intonly, accum+1) :
  (substr(str, pos-1, 1)=="." && !intonly) ? rnumlen(str, pos-1, true, accum+1)
  : accum;

function numat(str, pos=0, intonly=false, accum=0, divisor=0) =
  digitat(str, pos) >= 0 ?
    numat(str, pos+1, intonly, accum*10 + digitat(str, pos), divisor*10) :
  (substr(str, pos, 1) == "." && !intonly) ?
    numat(str, pos+1, true, accum, 1) :
  divisor == 0 ? accum : (accum / divisor);

function signnumat(str, pos=0, intonly=false) =
 !(digitat(str, pos+1) >= 0 || (substr(str, pos+1, 1) == "." && !intonly)) ?
    numat(str, pos, intonly) :
    substr(str, pos, 1) == "-" ? -numat(str, pos+1, intonly) :
    substr(str, pos, 1) == "+" ?  numat(str, pos+1, intonly) :
    numat(str, pos, intonly);

// self-test
function strutil_assert(actual, expected, msg) =
  actual == expected ? "ok" :
  str("FAILED: ", msg, " (EXPECTED:", expected, " ACTUAL:", actual, ")");

echo(strutil_assert(substr("abcd", 1, 2), "bc", "substr 1"));
echo(strutil_assert(substr("abcd", -1, 2), "a", "substr 2"));
echo(strutil_assert(substr("abcd", 3, 10), "d", "substr 3"));

echo(strutil_assert(indexof("abcd", "c"), 2, "indexof 1"));
echo(strutil_assert(indexof("abcd", "a", 1), -1, "indexof 2"));
echo(strutil_assert(indexof("abcd", "c", -5), 2, "indexof 3"));

echo(strutil_assert(rindexof("cbcd", "c"), 2, "rindexof 1"));
echo(strutil_assert(rindexof("cbcb", "cb", 2), 0, "rindexof 2"));

echo(strutil_assert(digitat("ab34x", 0), -1, "digitat 1"));
echo(strutil_assert(digitat("ab34x", 1), -1, "digitat 2"));
echo(strutil_assert(digitat("ab34x", 2),  3, "digitat 3"));
echo(strutil_assert(digitat("ab34x", 3),  4, "digitat 4"));
echo(strutil_assert(digitat("ab34x", 4), -1, "digitat 5"));

echo(strutil_assert(numlen("ab34.5x", 0),  0, "numlen 1"));
echo(strutil_assert(numlen("ab34.5x", 1),  0, "numlen 2"));
echo(strutil_assert(numlen("ab34.5x", 2),  4, "numlen 3"));
echo(strutil_assert(numlen("ab34.5x", 3),  3, "numlen 4"));
echo(strutil_assert(numlen("ab34.5x", 4),  2, "numlen 5"));
echo(strutil_assert(numlen("ab34.5x", 5),  1, "numlen 6"));
echo(strutil_assert(numlen("ab34.5x", 6),  0, "numlen 7"));
echo(strutil_assert(numlen("ab34.5x", 2, true),  2, "numlen 8"));

echo(strutil_assert(rnumlen("ab34.5x67"),  2, "rnumlen 1"));
echo(strutil_assert(rnumlen("ab34.5x", 1),  0, "rnumlen 2"));
echo(strutil_assert(rnumlen("ab34.5x", 2),  0, "rnumlen 3"));
echo(strutil_assert(rnumlen("ab34.5x", 3),  1, "rnumlen 4"));
echo(strutil_assert(rnumlen("ab34.5x", 4),  2, "rnumlen 5"));
echo(strutil_assert(rnumlen("ab34.5x", 5),  3, "rnumlen 6"));
echo(strutil_assert(rnumlen("ab34.5x", 6),  4, "rnumlen 7"));
echo(strutil_assert(rnumlen("ab34.5x", 7),  0, "rnumlen 8"));
echo(strutil_assert(rnumlen("ab34.5x", 6, true),  1, "rnumlen 9"));

echo(strutil_assert(numat("ab34.56x78"), 0, "numat 1"));
echo(strutil_assert(numat("ab34.56x78", 2), 34.56, "numat 2"));
echo(strutil_assert(numat("ab34.56x78", 2, true), 34, "numat 3"));

echo(strutil_assert(signnumat("x+34.5-67.89y", 1), 34.5, "signnumat 1"));
echo(strutil_assert(signnumat("x+34.5-67.89y", 6), -67.89, "signnumat 2"));
echo(strutil_assert(signnumat("x+34.5-67.89y", 6, true), -67, "signnumat 3"));
