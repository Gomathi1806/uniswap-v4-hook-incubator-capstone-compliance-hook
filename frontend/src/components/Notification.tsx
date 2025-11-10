import React, { useEffect } from 'react';
import { NotificationState } from '../../App';

interface NotificationProps {
  notification: NotificationState | null;
  onClose: () => void;
}

const Notification: React.FC<NotificationProps> = ({ notification, onClose }) => {
  useEffect(() => {
    if (notification) {
      const timer = setTimeout(() => {
        onClose();
      }, 5000); // Auto-dismiss after 5 seconds
      return () => clearTimeout(timer);
    }
  }, [notification, onClose]);

  if (!notification) return null;

  const baseClasses = 'fixed bottom-5 right-5 text-white px-6 py-3 rounded-lg shadow-lg flex items-center transition-opacity duration-300';
  const typeClasses = {
    success: 'bg-green-600',
    error: 'bg-red-600',
  };

  return (
    <div className={`${baseClasses} ${typeClasses[notification.type]}`}>
      <span className="mr-3">{notification.message}</span>
      <button onClick={onClose} className="font-bold text-xl leading-none">&times;</button>
    </div>
  );
};

export default Notification;
