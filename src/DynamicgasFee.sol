// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BaseHook} from "v4-periphery/src/utils/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {SwapParams} from "v4-core/types/PoolOperation.sol";

contract DynamicgasFee is BaseHook{
        using LPFeeLibrary for uint24;

        uint128 public movingAvarageGasPrice;
        uint104 public movingAverageGasPriceCount;
        uint24 public constant BASE_FEE = 5000;

        error MustHaveDynamicFee();
        constructor(IPoolManager _poolManager) BaseHook(_poolManager){
            updateMovingAverage();
        }

        function getHookPermissions() public pure override returns(Hooks.Permissions memory){
              return
            Hooks.Permissions({
                beforeInitialize: true,
                afterInitialize: false,
                beforeAddLiquidity: false,
                beforeRemoveLiquidity: false,
                afterAddLiquidity: false,
                afterRemoveLiquidity: false,
                beforeSwap: true,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false,
                beforeSwapReturnDelta: false,
                afterSwapReturnDelta: false,
                afterAddLiquidityReturnDelta: false,
                afterRemoveLiquidityReturnDelta: false
            });
        }

        function _beforeInitialize(address , PoolKey calldata key , uint160 sqrtPriceX96) internal pure override returns(bytes4){
            if(!key.fee.isDynamic()) revert MustHaveDynamicFee();
            return this.beforeInitialize.selector;
        }

        function _beforeSwap(address,PoolKey calldata key , SwapParams , bytes) internal view override returns (bytes4, BeforeSwapDelta, uint24){
            uint24 fee = getFee();
        
        uint24 feeWithFlag = fee | LPFeeLibrary.OVERRIDE_FEE_FLAG;
        return (
            this.beforeSwap.selector,
            BeforeSwapDeltaLibrary.ZERO_DELTA,
            feeWithFlag
        );
        } 

        function updateMovingAverage() internal {
            uint128 gasPrice = uint128(tx.gasPrice);

            movingAvarageGasPrice = ((movingAvarageGasPrice * movingAverageGasPriceCount) + gasPrice) / (movingAverageGasPriceCount + 1 );
        }
}