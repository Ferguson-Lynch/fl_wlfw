export function intersection(listA, listB) {
  if (!listA || !listB) return [];
  const result = [];
  for (const elem of listA) {
    if (listB.includes(elem)) {
      result.push(elem)
    }
  }
  return result;
}

//https://observablehq.com/@slowkow/vertical-color-legend