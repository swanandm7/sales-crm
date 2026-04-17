/**
 * Utility functions for generating communication links (tel:, mailto:, wa.me)
 * and formatting phone numbers for different contexts
 */

/**
 * Cleans a phone number by removing all non-digit characters except leading +
 */
export function cleanPhoneNumber(phoneNumber: string): string {
  if (!phoneNumber) return '';

  // Keep leading + for international format, remove everything else except digits
  const cleaned = phoneNumber.trim();
  if (cleaned.startsWith('+')) {
    return '+' + cleaned.slice(1).replace(/\D/g, '');
  }
  return cleaned.replace(/\D/g, '');
}

/**
 * Formats a phone number for WhatsApp wa.me URL
 * Removes all non-digit characters and ensures international format
 */
export function formatPhoneForWhatsApp(phoneNumber: string): string {
  if (!phoneNumber) return '';

  const cleaned = cleanPhoneNumber(phoneNumber);
  // Remove leading + for wa.me (it expects just digits)
  return cleaned.replace(/^\+/, '');
}

/**
 * Opens WhatsApp with pre-filled message using wa.me
 */
export function openWhatsApp(phoneNumber: string, message: string): boolean {
  if (!phoneNumber) {
    console.error('Phone number is required for WhatsApp');
    return false;
  }

  const formattedPhone = formatPhoneForWhatsApp(phoneNumber);
  const encodedMessage = encodeURIComponent(message);
  const url = `https://wa.me/${formattedPhone}?text=${encodedMessage}`;

  try {
    window.open(url, '_blank', 'noopener,noreferrer');
    return true;
  } catch (error) {
    console.error('Error opening WhatsApp:', error);
    return false;
  }
}

/**
 * Opens the default email client with pre-filled subject and body
 */
export function openEmailClient(
  emailAddress: string,
  subject: string,
  body: string
): boolean {
  if (!emailAddress) {
    console.error('Email address is required');
    return false;
  }

  const encodedSubject = encodeURIComponent(subject);
  const encodedBody = encodeURIComponent(body);
  const url = `mailto:${emailAddress}?subject=${encodedSubject}&body=${encodedBody}`;

  try {
    window.location.href = url;
    return true;
  } catch (error) {
    console.error('Error opening email client:', error);
    return false;
  }
}

/**
 * Opens the phone dialer with the specified number
 */
export function openPhoneDialer(phoneNumber: string): boolean {
  if (!phoneNumber) {
    console.error('Phone number is required');
    return false;
  }

  const cleanedPhone = cleanPhoneNumber(phoneNumber);
  const url = `tel:${cleanedPhone}`;

  try {
    window.location.href = url;
    return true;
  } catch (error) {
    console.error('Error opening phone dialer:', error);
    return false;
  }
}

/**
 * Copies text to clipboard
 */
export async function copyToClipboard(text: string): Promise<boolean> {
  try {
    await navigator.clipboard.writeText(text);
    return true;
  } catch (error) {
    console.error('Error copying to clipboard:', error);
    // Fallback for older browsers
    try {
      const textArea = document.createElement('textarea');
      textArea.value = text;
      textArea.style.position = 'fixed';
      textArea.style.left = '-999999px';
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand('copy');
      document.body.removeChild(textArea);
      return true;
    } catch (fallbackError) {
      console.error('Fallback copy failed:', fallbackError);
      return false;
    }
  }
}

/**
 * Validates if an email address has a basic valid format
 */
export function isValidEmail(email: string): boolean {
  if (!email) return false;
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Validates if a phone number has at least some digits
 */
export function isValidPhoneNumber(phoneNumber: string): boolean {
  if (!phoneNumber) return false;
  const cleaned = cleanPhoneNumber(phoneNumber);
  return cleaned.length >= 10; // Minimum 10 digits for a valid phone number
}

/**
 * Checks if a protocol (tel:, mailto:, etc.) is supported by the browser
 */
export function isProtocolSupported(protocol: 'tel' | 'mailto' | 'whatsapp'): boolean {
  // Basic check - most modern browsers support these
  // For WhatsApp, we use https:// so it's always supported
  if (protocol === 'whatsapp') return true;

  // For tel and mailto, they're widely supported
  // We'll assume support and handle errors gracefully
  return true;
}
