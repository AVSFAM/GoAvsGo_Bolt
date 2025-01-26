import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './index.css';

console.log('App starting...'); // Debug log

const rootElement = document.getElementById('root');
if (!rootElement) {
  console.error('Failed to find root element!');
  throw new Error('Failed to find root element');
}

const root = createRoot(rootElement);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);