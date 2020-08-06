import { ethers } from "@nomiclabs/buidler"

import * as utils from './utils/ethersutils'

import { Counter } from '../typechain/Counter'

async function main(): Promise<void> {
  const counter: Counter = (await utils.deployContract('Counter')) as Counter
  // eslint-disable-next-line no-console
  console.log(`Counter deployed: ${counter.address}`)
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    // eslint-disable-next-line no-console
    console.error(error)
    process.exit(1)
  })
