import { useEffect, useState, RefObject } from 'react';

interface DropdownPosition {
  openUpward: boolean;
  maxHeight: number;
}

export function useDropdownPosition(
  isOpen: boolean,
  dropdownRef: RefObject<HTMLDivElement>,
  defaultMaxHeight: number = 320
): DropdownPosition {
  const [openUpward, setOpenUpward] = useState(false);
  const [maxHeight, setMaxHeight] = useState(defaultMaxHeight);

  useEffect(() => {
    if (!isOpen || !dropdownRef.current) return;

    const element = dropdownRef.current;
    const rect = element.getBoundingClientRect();
    const viewportHeight = window.innerHeight;

    const spaceBelow = viewportHeight - rect.bottom;
    const spaceAbove = rect.top;

    const dropdownHeight = defaultMaxHeight;
    const threshold = 20;

    if (spaceBelow < dropdownHeight && spaceAbove > spaceBelow) {
      setOpenUpward(true);
      setMaxHeight(Math.min(spaceAbove - threshold, defaultMaxHeight));
    } else {
      setOpenUpward(false);
      setMaxHeight(Math.min(spaceBelow - threshold, defaultMaxHeight));
    }
  }, [isOpen, defaultMaxHeight]);

  return { openUpward, maxHeight };
}
