export function getCurrentBatchYears() {
  const currentYear = new Date().getFullYear();
  const currentMonth = new Date().getMonth();
  
  // Academic year starts in June (month 5)
  const isSecondHalf = currentMonth >= 5;
  
  const batchStartYear = isSecondHalf ? currentYear : currentYear - 1;
  
  return {
    firstYear: {
      start: batchStartYear,
      end: batchStartYear + 2,
    },
    secondYear: {
      start: batchStartYear - 1,
      end: batchStartYear + 1,
    },
  };
}

export function isActiveBatch(batchStartYear: number, batchEndYear: number): boolean {
  const current = getCurrentBatchYears();
  
  return (
    (batchStartYear === current.firstYear.start && batchEndYear === current.firstYear.end) ||
    (batchStartYear === current.secondYear.start && batchEndYear === current.secondYear.end)
  );
}

export function getBatchLabel(batchStartYear: number, batchEndYear: number): string {
  return `${batchStartYear}-${batchEndYear}`;
}
