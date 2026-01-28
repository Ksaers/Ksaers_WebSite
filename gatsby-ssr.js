/**
 * Implement Gatsby's SSR (Server Side Rendering) APIs in this file.
 *
 * We use this to preload and load the Inter font from Google Fonts
 * so visitors will see a consistent UI font if they don't have
 * the local `Calibre` font installed.
 */
const React = require('react');

exports.onRenderBody = ({ setHeadComponents }) => {
	setHeadComponents([
		// Preload common Inter woff2 weight (regular)
		<link
			key="preload-inter-regular"
			rel="preload"
			href="https://fonts.gstatic.com/s/inter/v12/UcCO3FwrK3iL.woff2"
			as="font"
			type="font/woff2"
			crossOrigin="anonymous"
		/>,
		// Load Inter stylesheet (Google Fonts)
		<link
			key="google-fonts-inter"
			href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
			rel="stylesheet"
		/>,
	]);
};