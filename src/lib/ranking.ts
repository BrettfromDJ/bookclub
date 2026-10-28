/**
 * Fractional ranking for drag-and-drop. A moved book gets a position between
 * its new neighbours, so only that one row is written.
 */
export function positionBetween(before: number | undefined, after: number | undefined): number {
  if (before === undefined && after === undefined) return 0;
  if (before === undefined) return (after as number) - 1;
  if (after === undefined) return before + 1;
  return (before + after) / 2;
}

/** Position for the item at `index` once it's moved there in `ordered` (which excludes the item). */
export function positionAt(ordered: { position: number }[], index: number): number {
  return positionBetween(ordered[index - 1]?.position, ordered[index]?.position);
}
