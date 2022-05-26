// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract SimplePaymentChannel {
    address payable public sender;      // Akun yang mengirim pembayaran.
    address payable public recipient;   // Rekening yang menerima pembayaran.
    uint256 public expiration;  // Timeout jika penerima tidak pernah menutup.

    constructor (address payable recipientAddress, uint256 duration)
        payable
    {
        sender = payable(msg.sender);
        recipient = recipientAddress;
        expiration = block.timestamp + duration;
    }

    /// penerima dapat menutup saluran kapan saja dengan menunjukkan
    /// jumlah yang ditandatangani dari pengirim. penerima akan dikirim sejumlah itu, 
    /// dan sisanya akan kembali ke pengirim
    function close(uint256 amount, bytes memory signature) external {
        require(msg.sender == recipient);
        require(isValidSignature(amount, signature));

        recipient.transfer(amount);
        selfdestruct(sender);
    }

    /// pengirim dapat memperpanjang masa berlakunya kapan saja
    function extend(uint256 newExpiration) external {
        require(msg.sender == sender);
        require(newExpiration > expiration);

        expiration = newExpiration;
    }

    /// jika batas waktu tercapai tanpa penerima menutup channel,
    /// maka Eter dilepaskan kembali ke pengirim.
    function claimTimeout() external {
        require(block.timestamp >= expiration);
        selfdestruct(sender);
    }

    function isValidSignature(uint256 amount, bytes memory signature)
        internal
        view
        returns (bool)
    {
        bytes32 message = prefixed(keccak256(abi.encodePacked(this, amount)));

        // periksa apakah tanda tangannya berasal dari pengirim pembayaran
        return recoverSigner(message, signature) == sender;
    }

    /// Semua fungsi di bawah ini hanya diambil dari bab
    /// 'membuat dan memverifikasi tanda tangan'.

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    /// membangun hash awalan untuk meniru perilaku eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}