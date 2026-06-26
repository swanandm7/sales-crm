import React from 'react';
import { Text } from 'react-native';
import * as LucideIcons from 'lucide-react-native';

type IconProps = {
  size?: number;
  color?: string;
  strokeWidth?: number;
};

function createIcon(LucideComponent: any, emoji: string) {
  const IconComponent = ({ size = 18, color = '#111827', strokeWidth }: IconProps) => {
    if (LucideComponent) {
      return <LucideComponent size={size} color={color} strokeWidth={strokeWidth} />;
    }
    return (
      <Text
        style={{
          color,
          fontSize: size * 0.85,
          lineHeight: size,
          textAlign: 'center',
          minWidth: size,
          fontWeight: '400',
        }}
      >
        {emoji}
      </Text>
    );
  };

  return IconComponent;
}

export const ArrowLeft = createIcon(LucideIcons.ArrowLeft, '←');
export const ArrowRight = createIcon(LucideIcons.ArrowRight, '→');
export const Bell = createIcon(LucideIcons.Bell, '🔔');
export const BellOff = createIcon(LucideIcons.BellOff, '🔕');
export const Building2 = createIcon(LucideIcons.Building2, '🏢');
export const Calendar = createIcon(LucideIcons.Calendar, '📅');
export const CalendarClock = createIcon(LucideIcons.CalendarClock, '⏰');
export const CheckCircle2 = createIcon(LucideIcons.CheckCircle2, '✅');
export const Circle = createIcon(LucideIcons.Circle, '⭕');
export const CircleAlert = createIcon(LucideIcons.CircleAlert, '⚠️');
export const ClipboardList = createIcon(LucideIcons.ClipboardList, '📋');
export const Clock = createIcon(LucideIcons.Clock, '🕐');
export const LogOut = createIcon(LucideIcons.LogOut, '🚪');
export const Mail = createIcon(LucideIcons.Mail, '✉️');
export const MessageCircle = createIcon(LucideIcons.MessageCircle, '💬');
export const Phone = createIcon(LucideIcons.Phone, '📞');
export const PhoneOff = createIcon(LucideIcons.PhoneOff, '📵');
export const PhoneForwarded = createIcon(LucideIcons.PhoneForwarded, '↪️');
export const PhoneCall = createIcon(LucideIcons.PhoneCall, '📲');
export const RefreshCcw = createIcon(LucideIcons.RefreshCcw, '🔄');
export const Search = createIcon(LucideIcons.Search, '🔍');
export const Shield = createIcon(LucideIcons.Shield, '🛡️');
export const Signal = createIcon(LucideIcons.Signal, '📶');
export const User = createIcon(LucideIcons.User, '👤');
export const Users = createIcon(LucideIcons.Users, '👥');
export const Filter = createIcon(LucideIcons.Filter, '⚙️');
export const Home = createIcon(LucideIcons.Home, '🏠');
export const MoreHorizontal = createIcon(LucideIcons.MoreHorizontal, '⋯');
export const Settings = createIcon(LucideIcons.Settings, '⚙️');
export const SlidersHorizontal = createIcon(LucideIcons.SlidersHorizontal, '🎛️');
export const X = createIcon(LucideIcons.X, '✕');
export const Eye = createIcon(LucideIcons.Eye, '👁');
export const EyeOff = createIcon(LucideIcons.EyeOff, '🙈');
export const Star = createIcon(LucideIcons.Star, '⭐');
export const TrendingUp = createIcon(LucideIcons.TrendingUp, '📈');
export const CheckMark = createIcon(LucideIcons.Check, '✓');
export const Save = createIcon(LucideIcons.Save, '💾');
export const Edit = createIcon(LucideIcons.Edit2, '✏️');
export const Trash = createIcon(LucideIcons.Trash2, '🗑️');
export const Plus = createIcon(LucideIcons.Plus, '➕');
export const Minus = createIcon(LucideIcons.Minus, '➖');
export const Info = createIcon(LucideIcons.Info, 'ℹ️');
export const Warning = createIcon(LucideIcons.AlertTriangle, '⚠️');
export const Success = createIcon(LucideIcons.CheckCircle, '✅');
export const Danger = createIcon(LucideIcons.XCircle, '❌');
export const Trophy = createIcon(LucideIcons.Trophy, '🏆');
export const Lock = createIcon(LucideIcons.Lock, '🔒');
