String maskWalletAccount(String acNo) {
  if (acNo.isEmpty) return '**** **** **** ****';
  if (acNo.length <= 4) return acNo;
  return '**** **** **** ${acNo.substring(acNo.length - 4)}';
}
