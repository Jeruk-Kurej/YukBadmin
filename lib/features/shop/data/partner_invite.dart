/// Toko partner tidak mendaftar sendiri: tim YukBadmin menghubungi toko,
/// lalu memberi kode undangan. Sampai ada server, kode yang berlaku ditulis
/// di sini (contoh untuk demo dan tes).
const partnerInviteCodes = {'MITRA-YB-2026'};

bool isValidPartnerCode(String code) =>
    partnerInviteCodes.contains(code.trim().toUpperCase());
