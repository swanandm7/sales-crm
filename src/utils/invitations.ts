export function buildInvitationLink(invitationToken: string) {
  return `https://sales-crm-24th.vercel.app/?token=${encodeURIComponent(invitationToken)}`;
}
