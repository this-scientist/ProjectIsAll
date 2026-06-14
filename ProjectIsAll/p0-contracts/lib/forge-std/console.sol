// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

library console {
    // forge 拦截发往该地址的 staticcall 并打印日志
    address constant CONSOLE_ADDRESS = 0x000000000000000000636F6e736F6c652e6c6f67;

    function _send(bytes memory payload) private view {
        address target = CONSOLE_ADDRESS;
        assembly {
            pop(staticcall(gas(), target, add(payload, 32), mload(payload), 0, 0))
        }
    }

    function log(string memory p0) internal view {
        _send(abi.encodeWithSignature("log(string)", p0));
    }

    function log(string memory p0, uint256 p1) internal view {
        _send(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _send(abi.encodeWithSignature("log(string,address)", p0, p1));
    }
}
