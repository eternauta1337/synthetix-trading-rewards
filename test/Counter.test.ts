import * as assert from 'assert'

import * as utils from '../src/utils/ethersutils'

// import { ethers } from '@nomiclabs/buidler'

import { Counter } from '../typechain/Counter'

describe('Counter', () => {
  let counter: Counter

  before('Deploy', async () => {
    counter = await utils.deployContract('Counter') as Counter
  })

  it('should count up', async () => {
    await counter.countUp()
    assert.equal(await counter.count(), 1)
  })
})