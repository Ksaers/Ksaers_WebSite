import React, { useState, useEffect } from 'react';
import { Link } from 'gatsby';
import { CSSTransition, TransitionGroup } from 'react-transition-group';
import styled, { css } from 'styled-components';
import { navLinks } from '@config';
import { navDelay, loaderDelay } from '@utils';
import { usePrefersReducedMotion, useScrollDirection } from '@hooks';

const StyledHeroSection = styled.section`
 ${({ theme }) => theme.mixins.flexCenter};
  flex-direction: column;
  align-items: flex-start;

  min-height: 100vh;
  height: 100vh;
  padding: 0;

  @media (max-height: 700px) and (min-width: 700px), (max-width: 360px) {
    height: auto;
    padding-top: var(--nav-height);
  }

  h1 {
    margin: 0 0 30px 4px;
    color: var(--green);
    font-family: var(--font-mono);
    font-size: clamp(var(--fz-sm), 5vw, var(--fz-md));
    font-weight: 400;

    @media (max-width: 480px) {
      margin: 0 0 20px 2px;
    }
  }

  h3 {
    margin-top: 5px;
    color: var(--slate);
    line-height: 0.9;
  }

  p {
    margin: 20px 0 0;
    max-width: 540px;
  }

  .email-link {
    ${({ theme }) => theme.mixins.bigButton};
    margin-top: 50px;
  }

  .nav-links {
    display: flex;
    align-items: center;
    margin-top: 50px;
    transition: opacity 0.3s ease, transform 0.3s ease;

    &.hidden {
      opacity: 0;
      transform: translateY(-20px);
    }

    @media (max-width: 768px) {
      display: none;
    }

    ol {
      ${({ theme }) => theme.mixins.flexBetween};
      padding: 0;
      margin: 0;
      list-style: none;

      li {
        margin: 0 5px;
        position: relative;
        counter-increment: item 1;
        font-size: var(--fz-xs);
        color: var(--lightest-slate);
        font-family: var(--font-mono);

        a {
          padding: 10px;

          &:before {
            content: '0' counter(item) '.';
            margin-right: 5px;
            color: var(--green);
            font-size: var(--fz-xxs);
            text-align: right;
          }
        }
      }
    }

    .resume-button {
      ${({ theme }) => theme.mixins.smallButton};
      margin-left: 15px;
      font-size: var(--fz-xs);
    }
  }
`;

const Hero = () => {
  const [isMounted, setIsMounted] = useState(false);
  const [showMenu, setShowMenu] = useState(true);
  const prefersReducedMotion = usePrefersReducedMotion();
  const scrollDirection = useScrollDirection('down');

  useEffect(() => {
    if (prefersReducedMotion) {
      return;
    }

    const timeout = setTimeout(() => setIsMounted(true), navDelay);
    return () => clearTimeout(timeout);
  }, []);

  useEffect(() => {
    if (scrollDirection === 'down') {
      setShowMenu(false);
    } else {
      setShowMenu(true);
    }
  }, [scrollDirection]);

  const one = <h1>Привет! Моё имя -</h1>;
  const two = <h2 className="big-heading">Андрей :)</h2>;
  const three = <h3 className="big-heading">Рад тебя видеть!</h3>;
  const four = (
    <>
      <p>
        В настоящее время я DevOps-инженер и специализируюсь на автоматизации, поддержке и стабильной работе серверной и облачной инфраструктуры.<br/>
          <br/>
          А также чуть-чуть Java-разработчик! 
           </p>
           </>
  ); 
  // const five = (
  //   <a
  //     className="email-link"
  //     href="https://www.newline.co/courses/build-a-spotify-connected-app"
  //     target="_blank"
  //     rel="noreferrer">
  //     Check out my course!
  //   </a>
  // );

  const items = [one, two, three, four, /*five*/];

  return (
    <StyledHeroSection>
      {prefersReducedMotion ? (
        <>
          {items.map((item, i) => (
            <div key={i}>{item}</div>
          ))}
          {showMenu && (
            <div className="nav-links">
              <ol>
                {navLinks.map(({ url, name }, i) => (
                  <li key={i}>
                    <a href={url}>{name}</a>
                  </li>
                ))}
              </ol>
              {/* <a className="resume-button" href="/resume.pdf" target="_blank" rel="noopener noreferrer">
                Резюме
              </a> */}
            </div>
          )}
        </>
      ) : (
        <TransitionGroup component={null}>
          {isMounted &&
            items.map((item, i) => (
              <CSSTransition key={i} classNames="fadeup" timeout={loaderDelay}>
                <div style={{ transitionDelay: `${i + 1}00ms` }}>{item}</div>
              </CSSTransition>
            ))}
          {isMounted && showMenu && (
            <CSSTransition classNames="fadeup" timeout={loaderDelay}>
              <div style={{ transitionDelay: '500ms' }} className="nav-links">
                <ol>
                  {navLinks.map(({ url, name }, i) => (
                    <li key={i}>
                      <a href={url}>{name}</a>
                    </li>
                  ))}
                </ol>
                {/* <a className="resume-button" href="/resume.pdf" target="_blank" rel="noopener noreferrer">
                  Резюме
                </a> */}
              </div>
            </CSSTransition>
          )}
        </TransitionGroup>
      )}
    </StyledHeroSection>
  );
};

export default Hero;
