// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Parapermit} from "./Parapermit.sol";

library ParaPermit {
    using SafeTransferLib for ERC20;

    function paraPermit(
        ERC20 token,
        Parapermit parapermit,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // TODO: idt the returndata decoding for nonce will be caught, should test with weth

        // Get and cache the starting nonce.
        try token.nonces(owner) returns (uint256 nonce) {
            // Attempt to call permit on the token.
            try token.permit(owner, spender, value, deadline, v, r, s) {} catch {
                // If permit didn't work, then we need to check if the owner is the spender.
                if (token.nonces(owner) != nonce + 1) parapermit.permit(owner, spender, value, deadline, v, r, s);
            }
        } catch {
            // If there is no nonce function, go straight to Parapermit.
            parapermit.permit(owner, spender, value, deadline, v, r, s);
        }
    }

    function paraTransferFrom(
        ERC20 token,
        Parapermit permit,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (token.allowance(from, address(this)) >= amount) {
            // Use normal transfer if possible.
            token.safeTransferFrom(from, to, amount);
        } else {
            // Otherwise try Parapermit (assume permit has already happened).
            permit.transferFrom(token, from, to, amount);
        }
    }
}