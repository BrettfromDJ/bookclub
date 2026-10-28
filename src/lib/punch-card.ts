export const HOLES_PER_CARD = 10;

/**
 * Coffee-shop style card: every finished book punches a hole, and ten holes
 * fill a card. A full card stays on screen (all punched) until the next book
 * starts a fresh one.
 */
export function punchCard(totalRead: number) {
  const total = Math.max(0, Math.floor(totalRead));
  const completedCards = Math.floor(total / HOLES_PER_CARD);
  const remainder = total % HOLES_PER_CARD;
  const showingFull = total > 0 && remainder === 0;
  return {
    cardNumber: showingFull ? completedCards : completedCards + 1,
    punched: showingFull ? HOLES_PER_CARD : remainder,
    holes: HOLES_PER_CARD,
    completedCards,
    toNextCard: showingFull ? HOLES_PER_CARD : HOLES_PER_CARD - remainder,
  };
}
