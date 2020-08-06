import * as assert from 'assert'

import * as utils from '../src/utils/ethersutils'

import { ethers } from '@nomiclabs/buidler'

import { RewardsToken } from '../typechain/RewardsToken'
import { TradingRewards } from '../typechain/TradingRewards'

describe('TradingRewards', () => {
  let ownerAddress: string
  let rewardsDistributionAddress: string
  let user1: string
  let user2: string

  let token: RewardsToken
  let rewards: TradingRewards

  before('Retrieve accounts', async () => {
    const accounts: string[] = await ethers.provider.listAccounts()

    ownerAddress = accounts[1]
    rewardsDistributionAddress = accounts[2]
    user1 = accounts[3]
    user2 = accounts[4]
  })

  before('Deploy SNX token', async () => {
    token = (await utils.deployContract('RewardsToken')) as RewardsToken
  })

  before('Deploy TradingRewards contract', async () => {
    rewards = (await utils.deployContract('TradingRewards', [
      ownerAddress,
      token.address,
      rewardsDistributionAddress
    ])) as TradingRewards
  })

  it('has a valid address', async () => {
    assert.ok(rewards.address.length > 0)
  })
})
