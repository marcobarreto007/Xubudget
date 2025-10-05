import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders Xuzinha dashboard', () => {
  render(<App />);
  const xuzinhaElement = screen.getByText(/XUBUDGET AI/i);
  expect(xuzinhaElement).toBeInTheDocument();
});