export function toPublicUser(row) {
  return {
    id: row.id,
    email: row.email,
    displayName: row.display_name,
    photoUrl: row.photo_url,
    bio: row.bio,
    status: row.status,
    partnerId: row.partner_id,
    coupleId: row.couple_id,
    anniversaryDate: row.anniversary_date,
    createdAt: row.created_at,
  };
}
