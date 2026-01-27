import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import styled, { ThemeProvider } from 'styled-components';
import { Head, Loader, Nav, Social, Email, Footer } from '@components';
import { GlobalStyle, theme } from '@styles';

const StyledContent = styled.div`
  display: flex;
  flex-direction: column;
  min-height: 100vh;
`;

const StyledCursor = styled.div`
  position: fixed;
  top: 0;
  left: 0;
  width: 600px;
  height: 600px;
  background: radial-gradient(
    circle,
    rgba(100, 255, 218, 0.05) 0%,
    rgba(100, 255, 218, 0.03) 20%,
    rgba(100, 255, 218, 0.02) 40%,
    transparent 70%
  );
  border-radius: 50%;
  pointer-events: none;
  z-index: 1;
  transition: transform 0.25s ease-out;
  transform-origin: center center;
  
  @media (max-width: 768px) {
    display: none;
  }
  
  @media (prefers-reduced-motion: reduce) {
    display: none;
  }
`;

const Layout = ({ children, location }) => {
  const isHome = location.pathname === '/';
  const [isLoading, setIsLoading] = useState(isHome);
  const [mousePosition, setMousePosition] = useState({ x: 0, y: 0 });

  // Cursor effect
  useEffect(() => {
    const updateMousePosition = (e) => {
      setMousePosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener('mousemove', updateMousePosition);
    return () => window.removeEventListener('mousemove', updateMousePosition);
  }, []);

  // Sets target="_blank" rel="noopener noreferrer" on external links
  const handleExternalLinks = () => {
    const allLinks = Array.from(document.querySelectorAll('a'));
    if (allLinks.length > 0) {
      allLinks.forEach(link => {
        if (link.host !== window.location.host) {
          link.setAttribute('rel', 'noopener noreferrer');
          link.setAttribute('target', '_blank');
        }
      });
    }
  };

  useEffect(() => {
    if (isLoading) {
      return;
    }
    if (location.hash) {
      const id = location.hash.substring(1); // location.hash without the '#'
      setTimeout(() => {
        const el = document.getElementById(id);
        if (el) {
          el.scrollIntoView();
          el.focus();
        }
      }, 0);
    }
    handleExternalLinks();
  }, [isLoading]);

  return (
    <>
      <Head />
      <div id="root">
        <ThemeProvider theme={theme}>
          <GlobalStyle />
          <StyledCursor
            style={{
              transform: `translate(${mousePosition.x - 300}px, ${mousePosition.y - 300}px)`,
            }}
          />
          <a className="skip-to-content" href="#content">
            Skip to Content
          </a>
          {isLoading && isHome ? (
            <Loader finishLoading={() => setIsLoading(false)} />
          ) : (
            <StyledContent>
              {!isHome && <Nav isHome={isHome} />}
              <Social isHome={isHome} />
              <Email isHome={isHome} />
              <div id="content">
                {children}
                <Footer />
              </div>
            </StyledContent>
          )}
        </ThemeProvider>
      </div>
    </>
  );
};

Layout.propTypes = {
  children: PropTypes.node.isRequired,
  location: PropTypes.object.isRequired,
};

export default Layout;