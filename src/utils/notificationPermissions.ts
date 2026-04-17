export interface NotificationPermissionState {
  granted: boolean;
  denied: boolean;
  prompt: boolean;
  supported: boolean;
}

export const checkNotificationSupport = (): boolean => {
  return 'Notification' in window && 'serviceWorker' in navigator;
};

export const getNotificationPermission = (): NotificationPermissionState => {
  const supported = checkNotificationSupport();

  if (!supported) {
    return {
      granted: false,
      denied: false,
      prompt: false,
      supported: false,
    };
  }

  const permission = Notification.permission;

  return {
    granted: permission === 'granted',
    denied: permission === 'denied',
    prompt: permission === 'default',
    supported: true,
  };
};

export const requestNotificationPermission = async (): Promise<NotificationPermissionState> => {
  if (!checkNotificationSupport()) {
    return getNotificationPermission();
  }

  try {
    const permission = await Notification.requestPermission();

    return {
      granted: permission === 'granted',
      denied: permission === 'denied',
      prompt: permission === 'default',
      supported: true,
    };
  } catch (error) {
    console.error('Error requesting notification permission:', error);
    return getNotificationPermission();
  }
};

export const showBrowserNotification = (
  title: string,
  options: NotificationOptions & { onClick?: () => void }
): Notification | null => {
  if (!checkNotificationSupport() || Notification.permission !== 'granted') {
    return null;
  }

  const { onClick, ...notificationOptions } = options;
  const notification = new Notification(title, notificationOptions);

  if (onClick) {
    notification.onclick = () => {
      window.focus();
      onClick();
      notification.close();
    };
  }

  return notification;
};

export const getStoredPermissionPreference = (): boolean | null => {
  const stored = localStorage.getItem('notification_permission_asked');
  return stored ? JSON.parse(stored) : null;
};

export const setStoredPermissionPreference = (asked: boolean): void => {
  localStorage.setItem('notification_permission_asked', JSON.stringify(asked));
};
