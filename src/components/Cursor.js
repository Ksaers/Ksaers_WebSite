import React, { useEffect, useState } from 'react';
import styled from 'styled-components';

const StyledCursor = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  width: 20px;
  height: 20px;
  background: radial-gradient(
    circle,
    rgba(100, 255, 218, 0.8) 0%,
    rgba(100, 255, 218, 0.4) 40%,
    transparent 70%
  );
  border-radius: 50%;
  pointer-events: none;
  z-index: 9999;
  transition: transform 0.1s ease-out;
  mix-blend-mode: difference;
`;

const Cursor = () => {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const updatePosition = (e) => {
      setPosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener('mousemove', updatePosition);
    return () => window.removeEventListener('mousemove', updatePosition);
  }, []);

  return (
    <StyledCursor
      style={{
        transform: `translate(${position.x - 10}px, ${position.y - 10}px)`,
      }}
    />
  );
};

export default Cursor;